#!/usr/bin/env bash
# Builds PixSEO, installs it to /Applications, and enables the Finder extension.
# Only replaces an existing /Applications/PixSEO.app if it really is PixSEO.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="/Applications/PixSEO.app"
BUNDLE_ID="app.pixseo.mac"
EXT_ID="app.pixseo.mac.FinderSync"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

"$ROOT/scripts/build-app.sh" release

pkill -x PixSEO 2>/dev/null || true

if [[ -d "$DEST" ]]; then
  existing="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DEST/Contents/Info.plist" 2>/dev/null || true)"
  if [[ "$existing" != "$BUNDLE_ID" ]]; then
    echo "Refusing to replace $DEST: bundle id is '$existing', not $BUNDLE_ID" >&2
    exit 1
  fi
  rm -rf "$DEST"
fi

ditto "$ROOT/build/PixSEO.app" "$DEST"
"$LSREGISTER" -f -R "$DEST"
pluginkit -a "$DEST/Contents/PlugIns/PixSEOFinder.appex"
pluginkit -e use -i "$EXT_ID"

echo "==> Extension status:"
pluginkit -m -i "$EXT_ID" -v || true
open "$DEST"
