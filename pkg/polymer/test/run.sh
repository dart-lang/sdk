#!/bin/bash
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Usage: run from a Dart SVN checkout after building.

# bail on error
set -e

# Note: test.dart needs to be run from the root of the Dart checkout
DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
pushd $DIR/../../.. > /dev/null

echo "*** Running unit tests for Polymer.dart and its dependencies."

SUITES="pkg/polymer samples/third_party/todomvc"

CONFIG="-m release -r vm,drt,ff,chrome -c none,dart2js,dartanalyzer --checked $*"

CMD="xvfb-run ./tools/test.py $CONFIG $SUITES"
echo "*** $CMD"
$CMD

echo -e "[32mAll tests pass[0m"
