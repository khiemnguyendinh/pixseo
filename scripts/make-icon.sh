#!/usr/bin/env bash
# Regenerates Resources/App/AppIcon.icns from scripts/IconRenderer.swift.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
SET="$WORK/AppIcon.iconset"
mkdir -p "$SET"
swiftc -O "$ROOT/scripts/IconRenderer.swift" -o "$WORK/render"
for size in 16 32 128 256 512; do
  "$WORK/render" "$size" "$SET/icon_${size}x${size}.png"
  "$WORK/render" "$((size * 2))" "$SET/icon_${size}x${size}@2x.png"
done
iconutil -c icns "$SET" -o "$ROOT/Resources/App/AppIcon.icns"
rm -rf "$WORK"
echo "==> Resources/App/AppIcon.icns"
