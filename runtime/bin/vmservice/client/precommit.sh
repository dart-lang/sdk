#!/bin/sh

# A polymer application compiled with dart2js depends on
# 4 js files:
# 1) packages/shadow_dom/shadow_dom.debug.js
# 2) packages/custom_element/custom-elements.debug.js
# 3) packages/browser/interop.js
# 4) index.html_bootstrap.dart.precompiled.js

# This script rolls 1, 2, 3, and 4 into index.html_bootstrap.dart.js

# Relative paths to four scripts.
SHADOW_DOM="packages/shadow_dom/shadow_dom.debug.js"
CUSTOM_ELEMENTS="packages/custom_element/custom-elements.debug.js"
INTEROP="packages/browser/interop.js"
OBSERVATORY="index.html_bootstrap.dart.precompiled.js"

# Base directory
BASE="out/web"

INPUT="$BASE/$SHADOW_DOM"
INPUT="$INPUT $BASE/$CUSTOM_ELEMENTS"
INPUT="$INPUT $BASE/$INTEROP"
INPUT="$INPUT $BASE/$OBSERVATORY"

OUTPUT="$BASE/index.html_bootstrap.dart.js"

# Rolling
cat $INPUT > $OUTPUT
