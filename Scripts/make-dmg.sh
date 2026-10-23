#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ROOT="$PROJECT_ROOT/dist/Lingo Prism.app"
RELEASE_DIR="$PROJECT_ROOT/release"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_ROOT/Resources/Info.plist")"
OUTPUT="${1:-$RELEASE_DIR/Lingo-Prism-v${VERSION}-macOS.dmg}"

if [[ ! -d "$APP_ROOT" ]]; then
    printf 'Missing app bundle: %s\nRun Scripts/make-app.sh first.\n' "$APP_ROOT" >&2
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"
STAGING_ROOT="$(mktemp -d -t lingo-prism-dmg)"
trap 'rm -rf "$STAGING_ROOT"' EXIT

STAGING="$STAGING_ROOT/Lingo Prism"
mkdir -p "$STAGING"
ditto "$APP_ROOT" "$STAGING/Lingo Prism.app"
ln -s /Applications "$STAGING/Applications"

rm -f "$OUTPUT"
hdiutil create \
    -volname "Lingo Prism" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$OUTPUT"

printf 'Created %s\n' "$OUTPUT"
