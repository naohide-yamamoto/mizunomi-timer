# Security Policy

## Supported Versions

Only the latest public release of Mizunomi Timer is supported for security fixes.

## Reporting a Vulnerability

Please do not report sensitive security details in a public GitHub Issue.

Use GitHub private vulnerability reporting:

1. Open the repository on GitHub.
2. Go to **Security**.
3. Choose **Report a vulnerability**.

Do not include exploit code, detailed reproduction steps, private file paths, personal information, or screenshots containing sensitive information in a public Issue.

Helpful reports include:

- The affected Mizunomi Timer version or commit.
- Your macOS version and Mac model.
- A short description of the security concern.
- Minimal reproduction steps, shared privately when appropriate.
- Whether the issue appears to affect confidentiality, integrity, availability, or user trust.

Security reports are handled on a best-effort basis, but they are prioritised over ordinary bug reports.

## Scope

Security issues in scope include problems in:

- The Mizunomi Timer macOS app.
- The reminder panel, settings window, Help handling, and launch-at-login behaviour.
- Build scripts and release packaging.
- App signing, sandboxing, or entitlement configuration.

Issues outside this project's scope include:

- Vulnerabilities in macOS, Finder, the user's default web browser, or GitHub.
- Social engineering reports that do not involve a flaw in Mizunomi Timer.
- Requests for support on unsupported macOS versions.

## Security Posture

Mizunomi Timer is designed to keep its security surface small:

- It does not send data anywhere.
- It does not use analytics or telemetry.
- It does not save drinking history after the app quits.
- It stores only local settings in `UserDefaults`.
- It does not request network, file access, camera, microphone, contacts, screen recording, or accessibility entitlements.
- It is built with the macOS App Sandbox entitlement.
- Launch at login uses Apple's `SMAppService` API rather than custom launch scripts.
- Public release builds are signed with a Developer ID certificate and notarised by Apple.
