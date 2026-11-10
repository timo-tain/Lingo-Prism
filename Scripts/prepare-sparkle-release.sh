#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ROOT="$PROJECT_ROOT/dist/Lingo Prism.app"
RELEASE_DIR="$PROJECT_ROOT/release"
SPARKLE_TOOLS="$PROJECT_ROOT/.build/artifacts/sparkle/Sparkle/bin"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_ROOT/Resources/Info.plist")"
TAG="v${VERSION}"
ARCHIVE_NAME="Lingo-Prism-v${VERSION}-macOS.zip"
FEED_URL="https://github.com/timo-tain/Lingo-Prism/releases/latest/download/appcast.xml"
DOWNLOAD_PREFIX="https://github.com/timo-tain/Lingo-Prism/releases/download/${TAG}/"
RELEASE_NOTES_URL="https://github.com/timo-tain/Lingo-Prism/releases/tag/${TAG}"

if [[ ! -x "$SPARKLE_TOOLS/generate_appcast" ]]; then
    printf 'Sparkle tools not found. Run: swift package resolve\n' >&2
    exit 1
fi

"$PROJECT_ROOT/Scripts/make-app.sh"
mkdir -p "$RELEASE_DIR"
WORK_DIR="$(mktemp -d -t lingo-prism-sparkle)"
trap 'rm -rf "$WORK_DIR"' EXIT

ditto -c -k --sequesterRsrc --keepParent "$APP_ROOT" "$WORK_DIR/$ARCHIVE_NAME"

# Carry forward the current feed when a previous Sparkle release exists.
# A 404 is expected while preparing the first Sparkle-enabled release.
HTTP_STATUS="$(curl --silent --show-error --location \
    --output "$WORK_DIR/appcast.xml" \
    --write-out '%{http_code}' \
    "$FEED_URL")"
case "$HTTP_STATUS" in
    200) ;;
    404) rm -f "$WORK_DIR/appcast.xml" ;;
    *) printf 'Could not read the existing update feed (HTTP %s).\n' "$HTTP_STATUS" >&2; exit 1 ;;
esac

SPARKLE_SIGNING_ARGS=()
if [[ -n "${SPARKLE_PRIVATE_KEY_PATH:-}" ]]; then
    if [[ ! -r "$SPARKLE_PRIVATE_KEY_PATH" ]]; then
        printf 'Sparkle private key is not readable: %s\n' "$SPARKLE_PRIVATE_KEY_PATH" >&2
        exit 1
    fi
    SPARKLE_SIGNING_ARGS=(--ed-key-file "$SPARKLE_PRIVATE_KEY_PATH")
fi

"$SPARKLE_TOOLS/generate_appcast" \
    "${SPARKLE_SIGNING_ARGS[@]}" \
    --download-url-prefix "$DOWNLOAD_PREFIX" \
    --full-release-notes-url "$RELEASE_NOTES_URL" \
    "$WORK_DIR"

install -m 644 "$WORK_DIR/$ARCHIVE_NAME" "$RELEASE_DIR/$ARCHIVE_NAME"
install -m 644 "$WORK_DIR/appcast.xml" "$RELEASE_DIR/appcast.xml"

printf '\nPrepared Sparkle release assets:\n  %s\n  %s\n' \
    "$RELEASE_DIR/$ARCHIVE_NAME" "$RELEASE_DIR/appcast.xml"
printf 'Upload both files to GitHub Release %s.\n' "$TAG"
