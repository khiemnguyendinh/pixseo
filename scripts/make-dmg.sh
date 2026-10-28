#!/usr/bin/env bash
# Builds a universal (Apple silicon + Intel) PixSEO.app and packs it into
# release/PixSEO-<version>.dmg with an Applications shortcut and the install guide.
#
# Env: PIXSEO_SIGN_ID (default "-", ad-hoc). With a Developer ID, notarize the DMG afterwards.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/App/Info.plist)"
OUT="release"
DMG="$OUT/PixSEO-$VERSION.dmg"

PIXSEO_ARCHS="${PIXSEO_ARCHS:-arm64 x86_64}" scripts/build-app.sh release

WORK="$(mktemp -d)"
STAGE="$WORK/PixSEO"
mkdir -p "$STAGE" "$OUT"
ditto build/PixSEO.app "$STAGE/PixSEO.app"
ln -s /Applications "$STAGE/Applications"
cp Resources/DMG/HUONG-DAN-CAI-DAT.txt "$STAGE/Hướng dẫn cài đặt.txt"

rm -f "$DMG"
hdiutil create -volname "PixSEO $VERSION" -srcfolder "$STAGE" -fs HFS+ -format UDZO -imagekey zlib-level=9 "$DMG" >/dev/null
rm -rf "$WORK"
(cd "$OUT" && shasum -a 256 "PixSEO-$VERSION.dmg" > "PixSEO-$VERSION.dmg.sha256")
echo "==> $DMG ($(du -h "$DMG" | cut -f1))"
cat "$DMG.sha256"
