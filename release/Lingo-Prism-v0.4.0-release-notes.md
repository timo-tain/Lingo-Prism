# Lingo Prism v0.4.0

Lingo Prism is a native macOS screen translator. Select an area on screen and receive a translation overlaid at the original text position.

## Highlights

- Added in-app update checks and Sparkle-powered installation from GitHub Releases.
- Added update-flow simulation in the debug panel.
- Added Screen Recording and Accessibility permission status and shortcuts to System Settings.
- Improved selection feedback, error hints, and global shortcut settings.
- Refreshed the menu bar and application branding.

## Install

1. Download `Lingo-Prism-v0.4.0-macOS.dmg`.
2. Open the DMG and drag **Lingo Prism.app** to the **Applications** shortcut.
3. Open the app from the menu bar and grant Screen Recording and Accessibility permissions as needed.

The ZIP archive is also available for users who prefer to inspect the app bundle directly.

## Update notes

- The app checks GitHub Releases for updates and verifies update archives with Sparkle's EdDSA signature.
- The first Sparkle-enabled release must be installed manually by users of v0.3.0. Later releases can be installed from within the app.
- This build is ad-hoc signed and not notarized. macOS may require you to approve opening it in Privacy & Security.
- Changing the Bundle ID may cause macOS to request Screen Recording and Accessibility permissions again.
