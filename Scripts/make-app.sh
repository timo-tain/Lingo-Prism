#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ROOT="$PROJECT_ROOT/dist/Lingo Prism.app"
EXECUTABLE="$PROJECT_ROOT/.build/release/LingoPrism"
SPARKLE_FRAMEWORK="$PROJECT_ROOT/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"

cd "$PROJECT_ROOT"
swift "$PROJECT_ROOT/Scripts/make-icons.swift" "$PROJECT_ROOT"
iconutil -c icns "$PROJECT_ROOT/Resources/LingoPrism.iconset" -o "$PROJECT_ROOT/Resources/LingoPrism.icns"
swift build -c release

mkdir -p "$APP_ROOT/Contents/MacOS" "$APP_ROOT/Contents/Resources" "$APP_ROOT/Contents/Frameworks"
install -m 755 "$EXECUTABLE" "$APP_ROOT/Contents/MacOS/LingoPrism"
ditto "$SPARKLE_FRAMEWORK" "$APP_ROOT/Contents/Frameworks/Sparkle.framework"
install_name_tool -add_rpath '@loader_path/../Frameworks' "$APP_ROOT/Contents/MacOS/LingoPrism"
install -m 644 "$PROJECT_ROOT/Resources/Info.plist" "$APP_ROOT/Contents/Info.plist"
install -m 644 "$PROJECT_ROOT/Resources/LingoPrism.icns" "$APP_ROOT/Contents/Resources/LingoPrism.icns"
install -m 644 "$PROJECT_ROOT/Resources/LingoPrismBrand.png" "$APP_ROOT/Contents/Resources/LingoPrismBrand.png"
install -m 644 "$PROJECT_ROOT/Resources/LingoPrismMenuBar.png" "$APP_ROOT/Contents/Resources/LingoPrismMenuBar.png"
# User-supplied image files can carry Finder metadata; code signing rejects
# these non-content attributes inside an app bundle.
xattr -cr "$APP_ROOT"
# No Apple Development identity is installed on this Mac.  Keep the local ad-hoc
# signature's designated requirement stable so TCC does not discard Screen Recording
# access every time the executable is rebuilt. Distribution builds must replace this
# with a Developer ID or App Store identity.
codesign --force --sign - \
  --identifier com.timo-tain.lingoprism \
  --requirements '=designated => identifier "com.timo-tain.lingoprism"' \
  "$APP_ROOT"

printf 'Built %s\n' "$APP_ROOT"
