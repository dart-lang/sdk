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
#
# 1. After running go.sh libraries in sdk/lib may change.
# 2. Build Dartium.
# 3. Run this script and sdk/lib/js/dartium/cached_patches will be created.
# 4. Rebuild Dartium.
# 5. Commit files in sdk/lib
#
# NOTE: If the Dart files generated from the IDLs may cause major changes which
#       could cause the patch files to fail (missing classes, etc).  If this
#       happens delete the contents of the sdk/lib/js/dartium/cached_patches.dart
#       build Dartium, run this script and build Dartium again with the newly
#       generated patches. 

ARG_OPTION="dartGenCachedPatches"

LOCATION_DARTIUM="../../../out/Release"
DARTIUM="$LOCATION_DARTIUM"

if [[ "$1" != "" ]] ; then
  if [[ "$1" =~ ^--roll ]]; then
      ARG_OPTION="dartGenCachedPatchesForRoll"
  else
      DARTIUM="$1"
  fi
fi

if [[ "$2" != "" ]] ; then
  if [[ "$2" =~ ^--roll ]]; then
      ARG_OPTION="dartGenCachedPatchesForRoll"
  else
      DARTIUM="$2"
  fi
fi

DART_APP_LOCATION="file://"$PWD"/generate_app/generate_cached_patches.html"
DARTIUM_ARGS=" --user-data-dir=out --disable-web-security --no-sandbox --enable-blink-features="$ARG_OPTION""
CACHED_PATCHES_FILE=""$PWD"/../../sdk/lib/js/dartium/cached_patches.dart"

cmd=""$DARTIUM"/chrome "$DARTIUM_ARGS" "$DART_APP_LOCATION" |
  (sed -n '/START_OF_CACHED_PATCHES/,/END_OF_CACHED_PATCHES/p') > "$CACHED_PATCHES_FILE""

reset && eval "${cmd}"


