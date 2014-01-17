#!/bin/bash
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Script to create AppCache manifest.

echo CACHE MANIFEST

date +'# %s'

echo CACHE:

PKG_DIR="$(cd $(dirname ${0})/../pkg ; pwd)"
SDK_DIR="$(cd $(dirname ${0})/../sdk ; pwd)"
LIVE_DIR="$(cd $(dirname ${0})/../web_editor ; pwd)"

echo ${PKG_DIR}/browser/lib/dart.js | sed -e "s|$(pwd)/||"

# find ${SDK_DIR} \
#     \( -name dartdoc -o -name pub -o -name dartium \) -prune \
#     -o -name \*.dart -print \
#     | sed -e "s|$(pwd)/||"

find ${LIVE_DIR} \
    \( -name \*~ \) -prune \
    -o -type f -print | sed -e "s|$(pwd)/||"

echo iframe.html
echo iframe.js
echo dart-icon.png
echo dart-iphone5.png

echo NETWORK:
echo '*'
