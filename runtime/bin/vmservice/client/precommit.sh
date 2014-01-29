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
OBSERVATORY_DEVTOOLS="index_devtools.html_bootstrap.dart.precompiled.js"

# Base directory
BASE="out/web"
DEPLOYED="deployed/web"

INPUT="$BASE/$SHADOW_DOM"
INPUT="$INPUT $BASE/$CUSTOM_ELEMENTS"
INPUT="$INPUT $BASE/$INTEROP"

INPUT_STANDALONE="$INPUT $BASE/$OBSERVATORY"
OUTPUT_STANDALONE="$DEPLOYED/index.html_bootstrap.dart.js"

# Rolling
cat $INPUT_STANDALONE > $OUTPUT_STANDALONE
cp $BASE/index.html $DEPLOYED/index.html

INPUT_DEVTOOLS="$INPUT $BASE/$OBSERVATORY_DEVTOOLS"
OUTPUT_DEVTOOLS="$DEPLOYED/index_devtools.html_bootstrap.dart.js"

cat $INPUT_DEVTOOLS > $OUTPUT_DEVTOOLS
cp $BASE/index_devtools.html $DEPLOYED/index_devtools.html

# Kill package <script> tags added by polymer compilation.
# This kills harmless (but distracting) Chrome Developer Console spam
# about missing scripts.
perl -pi -e 's/<script src="packages.*"><\/script>//g' \
    $DEPLOYED/index.html
perl -pi -e 's/<script src="packages.*"><\/script>//g' \
    $DEPLOYED/index_devtools.html

# The polymer compilation step munges <img> src urls and adds a packages/
# prefix to the url. Because of how we deploy we must undo this and remove
# the prefix. Without this, images will show up as broken links.
perl -pi -e 's/packages\/observatory\/src\/observatory_elements\///g' \
    $DEPLOYED/index.html
perl -pi -e 's/packages\/observatory\/src\/observatory_elements\///g' \
    $DEPLOYED/index_devtools.html