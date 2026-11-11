# Lingo Prism v0.4.1

Lingo Prism is a native macOS screen translator. Select an area on screen and receive a translation overlaid at the original text position.

## Highlights

- Update checks run silently when the menu bar popover is first opened each day.
- Available updates appear as passive notices in the menu bar popover and Settings, without opening a dialog automatically.
- Settings shows an **Update** action after a new version is found; selecting it opens Sparkle's update window.
- Added a simulated update mode in the debug panel to preview the update notice and prompt without network access or installation.
- The debug panel now opens after clicking the version number at the bottom of Settings ten times.

## Install

Download `Lingo-Prism-v0.4.1-macOS.dmg`, open it, and drag **Lingo Prism.app** to the **Applications** shortcut.

Users on v0.4.0 can install this release through the in-app updater. Users on v0.3.0 need to install a Sparkle-enabled release manually first.

## Update notes

- Update archives are verified with Sparkle's EdDSA signature.
- This build is ad-hoc signed and not notarized. macOS may require approval in Privacy & Security before opening it.
