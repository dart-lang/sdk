#!/usr/bin/env bash
#

set -x

#   generate_patches.sh [systems]
#
# Convenience script to generate patches for JsInterop under Dartium.  Do not call from build steps or tests
# - call fremontcutbuilder and dartdomgenerator instead. Do not add 'real'
# functionality here - change the python code instead.
#
# I find it essential to generate all the systems so I know if I am breaking
# other systems.  My habit is to run:
#
#   ./go.sh

# 1. After running go.sh libraries in sdk/lib may change.
# 2. Build Dartium.
# 3. Run this script and sdk/lib/js/dartium/cached_patches will be created.
# 4. Rebuild Dartium.
# 5. Commit files in sdk/lib

LOCATION_DARTIUM="../../../out/Release"
DARTIUM="$LOCATION_DARTIUM"

DART_APP_LOCATION="file://"$PWD"/generate_app/generate_cached_patches.html"
DARTIUM_ARGS=" --user-data-dir=out --disable-web-security --no-sandbox --enable-logging=stderr"
CACHED_PATCHES_FILE=""$PWD"/../../sdk/lib/js/dartium/cached_patches.dart"

if [[ "$1" != "" ]] ; then
  DARTIM="$1"
fi

cmd=""$DARTIUM"/chrome "$DARTIUM_ARGS" "$DART_APP_LOCATION" 3>&1 1>&2- 2>&3 | \
  (sed -n '/START_OF_CACHED_PATCHES/,/END_OF_CACHED_PATCHES/p') > "$CACHED_PATCHES_FILE""

reset && eval "${cmd}"


