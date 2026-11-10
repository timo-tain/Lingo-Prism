# Sparkle app updates

Lingo Prism uses Sparkle 2 for signed in-app updates. Update metadata and archives are hosted as static GitHub Release assets; no update server is required.

## Current setup

- The appcast URL is `https://github.com/timo-tain/Lingo-Prism/releases/latest/download/appcast.xml`.
- Each Sparkle-enabled GitHub Release must include `appcast.xml` and the versioned `Lingo-Prism-v<version>-macOS.zip` archive.
- Sparkle checks for updates automatically once a day and also has a manual **Check for Updates** button in Settings.
- Automatic installation is off. Sparkle presents its normal update dialog; the user chooses to download and install, then the app restarts to finish.
- The public EdDSA key is stored in `Resources/Info.plist`. The matching private key was generated into the developer's login Keychain under Sparkle's default `ed25519` account. Do not commit or share the private key.

## Preparing a release

1. Set a new, higher `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist`. Both values must advance from the last release; Sparkle orders updates by `CFBundleVersion`.
2. Run `Scripts/prepare-sparkle-release.sh`. It builds the app, creates a ZIP containing the app bundle, carries forward the existing appcast when available, and signs the feed entries using the local Keychain key.
3. Upload the generated ZIP and `release/appcast.xml` as assets on the GitHub Release whose tag is `v<CFBundleShortVersionString>`.
4. Keep the public `SUPublicEDKey` in the app unchanged. Keep a secure backup of the private key; without it, future update archives cannot be signed with the same key.

Keep publishing the DMG as well for first-time users. The currently published v0.3.0 does not contain Sparkle, so users on that version must install the first Sparkle-enabled release manually once. That first release should have a version higher than v0.3.0. Since its Bundle ID changes from `com.example.lingoprism` to `com.timo-tain.lingoprism`, macOS may ask users to grant Screen Recording and Accessibility permissions again.

## Apple Developer ID

The Sparkle EdDSA signature verifies each update archive independently of Apple's code signature, so it does not require an Apple Developer ID certificate. This project currently ad-hoc signs its app and does not enable the hardened runtime. That is suitable for local builds, but macOS Gatekeeper may warn users or require them to approve an app downloaded from GitHub. Public releases should ideally be signed with Developer ID and notarized; test ad-hoc Sparkle updates on a clean Mac before distributing them broadly.

The release script needs network access and the Sparkle command-line tools provided by the resolved Swift package. If the appcast URL returns 404, no Sparkle-enabled release has been published yet; a 404 is expected while preparing the first one. If the signing key has been exported from Keychain, pass its file path as `SPARKLE_PRIVATE_KEY_PATH` when running the release script. The exported private key is sensitive and must not be committed.
