#!/bin/bash
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Usage: call directly in the commandline as test/run.sh ensuring that you have
# 'dart' in your path. Filter tests by passing a pattern as an argument to this
# script.

# TODO(sigmund): replace with a real test runner

# bail on error
set -e

# print commands executed by this script
# set -x

DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
DART_FLAGS="--checked"
TEST_PATTERN=$1

if [[ ($TEST_PATTERN == "") ]]; then
  # Note: dart_analyzer needs to be run from the root directory for proper path
  # canonicalization.
  pushd $DIR/.. &>/dev/null
  echo Analyzing compiler for warnings or type errors
  dartanalyzer --fatal-warnings --fatal-type-errors bin/css.dart
  popd &>/dev/null
fi
 
pushd $DIR &>/dev/null
if [[ ($TEST_PATTERN == "canary") || ($TEST_PATTERN = "") ]]; then
  dart $DART_FLAGS run_all.dart
else
  dart $DART_FLAGS run_all.dart $TEST_PATTERN
fi
popd &>/dev/null

echo All tests completed.
