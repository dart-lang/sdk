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
pushd $DIR > /dev/null

POLYMER_REMOTE=https://github.com/Polymer
POLYMER_DIR=../../../third_party/polymer

for NAME in ShadowDOM observe-js WeakMap; do
  GIT_REMOTE="$POLYMER_REMOTE/$NAME.git"
  GIT_DIR="$POLYMER_DIR/$NAME"
  echo "*** Syncing $GIT_DIR from $GIT_REMOTE"
  if [ -d "$GIT_DIR" ]; then
    pushd $GIT_DIR > /dev/null
    git remote set-url origin $GIT_REMOTE
    git pull
    popd
  else
    git clone $GIT_REMOTE $GIT_DIR
  fi
done

echo '*** Installing NPM prerequisites'
npm install

echo '*** Running grunt'
grunt
