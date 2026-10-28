#!/usr/bin/env bash
# Builds build/PixSEO.app with its Finder extension, using Command Line Tools only (no Xcode).
#
#   scripts/build-app.sh [release|debug]
#
# Env:
#   PIXSEO_ARCHS    space-separated archs, default: this Mac's arch ("arm64 x86_64" = universal)
#   PIXSEO_SIGN_ID  codesign identity, default "-" (ad-hoc)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${1:-release}"
ARCHS="${PIXSEO_ARCHS:-$(uname -m)}"
SIGN_ID="${PIXSEO_SIGN_ID:--}"
MIN_OS="14.0"

OUT="$ROOT/build"
APP="$OUT/PixSEO.app"
APPEX="$APP/Contents/PlugIns/PixSEOFinder.appex"
SDK="$(xcrun --show-sdk-path)"

cd "$ROOT"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APPEX/Contents/MacOS" "$OUT/obj"

app_bins=()
ext_bins=()
for arch in $ARCHS; do
  triple="$arch-apple-macosx$MIN_OS"
  echo "==> Building app ($arch, $CONFIG)"
  swift build -c "$CONFIG" --product PixSEOApp --triple "$triple"
  app_bins+=("$(swift build -c "$CONFIG" --product PixSEOApp --triple "$triple" --show-bin-path)/PixSEOApp")

  # The extension needs the _NSExtensionMain entry point and app-extension-safe linking, which
  # SwiftPM executables can't express, so it is compiled directly with the shared sources.
  # Swift 5 mode: FIFinderSync's overrides aren't actor-annotated, and Finder calls them on main.
  echo "==> Building Finder extension ($arch)"
  ext_bin="$OUT/obj/PixSEOFinder-$arch"
  opt=$([[ "$CONFIG" == "release" ]] && echo "-O" || echo "-Onone -g")
  swiftc $opt -swift-version 5 -sdk "$SDK" -target "$arch-apple-macos$MIN_OS" \
    -application-extension -module-name PixSEOFinderExt \
    -Xlinker -e -Xlinker _NSExtensionMain -Xlinker -application_extension \
    Sources/PixSEOFinderExt/*.swift Sources/PixSEOShared/*.swift \
    -o "$ext_bin"
  ext_bins+=("$ext_bin")
done

echo "==> Assembling bundle"
lipo -create "${app_bins[@]}" -output "$APP/Contents/MacOS/PixSEO"
lipo -create "${ext_bins[@]}" -output "$APPEX/Contents/MacOS/PixSEOFinder"
cp Resources/App/Info.plist "$APP/Contents/Info.plist"
cp Resources/FinderExt/Info.plist "$APPEX/Contents/Info.plist"
[[ -f Resources/App/AppIcon.icns ]] && cp Resources/App/AppIcon.icns "$APP/Contents/Resources/"
cp LICENSE THIRD_PARTY_NOTICES "$APP/Contents/Resources/"
plutil -lint "$APP/Contents/Info.plist" "$APPEX/Contents/Info.plist" >/dev/null

echo "==> Signing ($SIGN_ID)"
# Inside-out: the extension first (sandboxed), then the app. Hardened runtime is on so the same
# bundle can be notarized when a Developer ID is used.
codesign --force --sign "$SIGN_ID" --options runtime --timestamp=none \
  --entitlements Resources/FinderExt/FinderExt.entitlements "$APPEX"
codesign --force --sign "$SIGN_ID" --options runtime --timestamp=none "$APP"
codesign --verify --strict --verbose=1 "$APP"

echo "==> Built $APP ($(lipo -archs "$APP/Contents/MacOS/PixSEO"))"
