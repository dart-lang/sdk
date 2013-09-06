#!/bin/bash
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Usage: call directly in the commandline as test/run.sh ensuring that you have
# both 'dart' and 'content_shell' in your path. Filter tests by passing a
# pattern as an argument to this script.

# bail on error
set -e

DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
# Note: dartanalyzer and some tests needs to be run from the root directory
pushd $DIR > /dev/null

SHADOWDOM_REMOTE=https://github.com/dart-lang/ShadowDOM.git
SHADOWDOM_DIR=../../../third_party/polymer/ShadowDOM

echo "*** Syncing $SHADOWDOM_DIR from $SHADOWDOM_REMOTE"
if [ -d "$SHADOWDOM_DIR" ]; then
  pushd $SHADOWDOM_DIR > /dev/null
  git pull
  popd
else
  git clone --branch shadowdom_patches $SHADOWDOM_REMOTE $SHADOWDOM_DIR
fi

echo '*** Installing NPM prerequisites'
npm install

echo '*** Running grunt'
grunt
