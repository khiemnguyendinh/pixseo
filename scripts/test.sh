#!/usr/bin/env bash
# Runs `swift test` with Command Line Tools only.
# CLT ships swift-testing outside SwiftPM's default search paths, so they are passed explicitly.
# With Xcode installed, plain `swift test` also works.
set -euo pipefail
cd "$(dirname "$0")/.."

DEV="$(xcode-select -p)"
FRAMEWORKS="$DEV/Library/Developer/Frameworks"
LIBS="$DEV/Library/Developer/usr/lib"

if [[ -d "$FRAMEWORKS/Testing.framework" ]]; then
  exec swift test \
    -Xswiftc -F -Xswiftc "$FRAMEWORKS" \
    -Xlinker -F -Xlinker "$FRAMEWORKS" \
    -Xlinker -rpath -Xlinker "$FRAMEWORKS" \
    -Xlinker -rpath -Xlinker "$LIBS" \
    "$@"
fi
exec swift test "$@"
