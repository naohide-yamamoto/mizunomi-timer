#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Mizunomi Timer"
APP_DIR="$ROOT_DIR/build/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/build/release"
ENTITLEMENTS_FILE="$ROOT_DIR/Resources/MizunomiTimer.entitlements"
INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
NOTARIZE="${NOTARIZE:-1}"

if [[ -z "$SIGNING_IDENTITY" ]]; then
  echo "SIGNING_IDENTITY is required, for example:" >&2
  echo "  SIGNING_IDENTITY=\"Developer ID Application: Your Name (TEAMID)\" NOTARY_PROFILE=\"mizunomi-timer-notary\" bash scripts/release-app.sh" >&2
  exit 64
fi

if [[ "$NOTARIZE" != "0" && -z "$NOTARY_PROFILE" ]]; then
  echo "NOTARY_PROFILE is required unless NOTARIZE=0." >&2
  echo "Create one with xcrun notarytool store-credentials, then pass its profile name." >&2
  exit 64
fi

VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")"
RELEASE_BASENAME="Mizunomi-Timer-$VERSION"
NOTARY_ZIP="$DIST_DIR/$RELEASE_BASENAME-notary.zip"
RELEASE_ZIP="$DIST_DIR/$RELEASE_BASENAME.zip"
CHECKSUM_FILE="$DIST_DIR/$RELEASE_BASENAME-SHA256.txt"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "Building unsigned app bundle..."
CONFIGURATION=release SKIP_CODESIGN=1 bash "$ROOT_DIR/scripts/build-app.sh"

echo "Signing with Developer ID..."
codesign \
  --force \
  --sign "$SIGNING_IDENTITY" \
  --options runtime \
  --timestamp \
  --entitlements "$ENTITLEMENTS_FILE" \
  "$APP_DIR" >/dev/null

codesign --verify --strict --verbose=2 "$APP_DIR"

if [[ "$NOTARIZE" != "0" ]]; then
  echo "Creating notarization ZIP..."
  ditto -c -k --keepParent "$APP_DIR" "$NOTARY_ZIP"

  echo "Submitting to Apple notarization service..."
  xcrun notarytool submit "$NOTARY_ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

  echo "Stapling notarization ticket..."
  xcrun stapler staple "$APP_DIR"
  xcrun stapler validate "$APP_DIR"

  echo "Checking Gatekeeper assessment..."
  spctl --assess --type execute --verbose=4 "$APP_DIR"

  rm -f "$NOTARY_ZIP"
fi

echo "Creating release ZIP..."
ditto -c -k --keepParent "$APP_DIR" "$RELEASE_ZIP"

echo "Creating SHA256 checksum..."
(
  cd "$DIST_DIR"
  shasum -a 256 "$(basename "$RELEASE_ZIP")" > "$(basename "$CHECKSUM_FILE")"
)

echo "$RELEASE_ZIP"
echo "$CHECKSUM_FILE"
