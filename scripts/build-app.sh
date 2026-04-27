#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="Mizunomi Timer"
EXECUTABLE_NAME="MizunomiTimer"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SCRATCH_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mizunomi-timer-swiftpm-$CONFIGURATION.XXXXXX")"
CACHE_DIR="$SCRATCH_DIR/cache"
CONFIG_DIR="$SCRATCH_DIR/config"
SECURITY_DIR="$SCRATCH_DIR/security"
MODULE_CACHE_DIR="$SCRATCH_DIR/clang-module-cache"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"

mkdir -p "$BUILD_DIR" "$MACOS_DIR" "$RESOURCES_DIR" "$CACHE_DIR" "$CONFIG_DIR" "$SECURITY_DIR" "$MODULE_CACHE_DIR"

export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR"

SWIFT_BUILD_ARGS=(
  --disable-sandbox
  --manifest-cache local
  --cache-path "$CACHE_DIR"
  --config-path "$CONFIG_DIR"
  --security-path "$SECURITY_DIR"
  --scratch-path "$SCRATCH_DIR"
  -c "$CONFIGURATION"
  --arch arm64
  -debug-info-format none
)

swift build "${SWIFT_BUILD_ARGS[@]}"
BIN_PATH="$(swift build --show-bin-path "${SWIFT_BUILD_ARGS[@]}")"

cp "$BIN_PATH/$EXECUTABLE_NAME" "$MACOS_DIR/$EXECUTABLE_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Resources/UserManual.html" "$RESOURCES_DIR/UserManual.html"

swift "$ROOT_DIR/scripts/generate-app-icon.swift" "$ICONSET_DIR" "$RESOURCES_DIR/AppIcon.icns"
cp "$ICONSET_DIR/icon_128x128.png" "$RESOURCES_DIR/HelpIcon.png"
cp "$ICONSET_DIR/icon_32x32.png" "$RESOURCES_DIR/favicon.png"

if [[ "${SKIP_CODESIGN:-0}" != "1" ]]; then
  codesign --force --sign - "$APP_DIR" >/dev/null
fi

touch "$APP_DIR"

echo "$APP_DIR"
