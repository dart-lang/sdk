#!/bin/bash
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Usage: call directly in the commandline as test/run.sh ensuring that you have
# both 'dart' and 'content_shell' in your path. Filter tests by passing a
# pattern as an argument to this script.

# TODO(sigmund): replace with a real test runner

# bail on error
set -e

# print commands executed by this script
# set -x

DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
# Note: dartanalyzer and some tests needs to be run from the root directory
pushd $DIR/.. > /dev/null

export DART_FLAGS="--checked"

# Search for the first argument that doesn't look like an option ('--foo')
function first_non_option {
  while [[ $# -gt 0 ]]; do
    if [[ $1 != --* ]]; then # Note: --* is a regex
      echo $1
      return
    fi
    shift
  done
}

TEST_PATTERN=$(first_non_option $@)

SDK_DIR=$(cd ../../out/ReleaseIA32/dart-sdk/; pwd)
package_root=$SDK_DIR/../packages
dart="$SDK_DIR/bin/dart --package-root=$package_root"
dartanalyzer="$SDK_DIR/bin/dartanalyzer --package-root=$package_root"

function fail {
  return 1
}

function show_diff {
  diff -u -N $1 $2 | \
    sed -e "s/^\(+.*\)/[32m\1[0m/" |\
    sed -e "s/^\(-.*\)/[31m\1[0m/"
  return 1
}

function update {
  read -p "Would you like to update the expectations? [y/N]: " answer
  if [[ $answer == 'y' || $answer == 'Y' ]]; then
    cp $2 $1
    return 0
  fi
  return 1
}

function pass {
  echo -e "[32mOK[0m"
}

function compare {
  # use a standard diff, if they are not identical, format the diff nicely to
  # see what's the error and prompt to see if they wish to update it. If they
  # do, continue running more tests.
  diff -q $1 $2 && pass || show_diff $1 $2 || update $1 $2
}

if [[ ($TEST_PATTERN == "") ]]; then
  echo Analyzing analyzer for warnings or type errors
  $dartanalyzer --hints --fatal-warnings --fatal-type-errors lib/dwc.dart

  echo Analyzing deploy-compiler for warnings or type errors
  $dartanalyzer --hints --fatal-warnings --fatal-type-errors lib/deploy.dart

  echo -e "\nAnalyzing runtime for warnings or type errors"
  $dartanalyzer --hints --fatal-warnings --fatal-type-errors lib/polymer.dart

  popd > /dev/null
fi

function compare_all {
# TODO(jmesserly): bash and dart regexp might not be 100% the same. Ideally we
# could do all the heavy lifting in Dart code, and keep this script as a thin
# wrapper that sets `--enable-type-checks --enable-asserts`
  for input in $DIR/../example/component/news/test/*_test.html; do
    if [[ ($TEST_PATTERN == "") || ($input =~ $TEST_PATTERN) ]]; then
      FILENAME=`basename $input`
      DIRNAME=`dirname $input`
      if [[ `basename $DIRNAME` == 'input' ]]; then
        DIRNAME=`dirname $DIRNAME`
      fi
      echo -e -n "Checking diff for $FILENAME "
      DUMP="test/data/out/example/test/$FILENAME.txt"
      EXPECTATION="$DIRNAME/expected/$FILENAME.txt"

      compare $EXPECTATION $DUMP
    fi
  done
  echo -e "[31mSome tests failed[0m"
  fail
}

if [[ ($TEST_PATTERN == "") ]]; then
  echo -e "\nTesting build.dart... "
  $dart $DART_FLAGS build.dart
  # Run it the way the editor does. Hide stdout because it is in noisy machine
  # format. Show stderr in case something breaks.
  # NOTE: not using --checked because the editor doesn't use it, and to workaround
  # http://dartbug.com/9637
  $dart build.dart --machine --clean > /dev/null
  $dart build.dart --machine --full > /dev/null
fi

echo -e "\nRunning unit tests... "
$dart $DART_FLAGS test/run_all.dart $@ || compare_all

# Run Dart analyzer to check that we're generating warning clean code.
# It's a bit slow, so only do this for one test.
OUT_PATTERN="$DIR/../example/component/news/test/out/test/*$TEST_PATTERN*_bootstrap.dart"
if [[ `ls $OUT_PATTERN 2>/dev/null` != "" ]]; then
  echo -e "\nAnalyzing generated code for warnings or type errors."
  ls $OUT_PATTERN 2>/dev/null | $dartanalyzer \
      --fatal-warnings --fatal-type-errors -batch
fi

echo -e "[32mAll tests pass[0m"
