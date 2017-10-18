#!/usr/bin/env bash
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Script to update the dart2js status lines for all tests running with the
# $dart2js_with_kernel test configuration.

suites=

for arg in "$@"; do
  case $arg in
    dart2js_native|dart2js_extra|language|language_2|corelib|corelib_2|html)
      suites="$suites $arg"
      ;;
    -*)
      echo "Unknown option '$arg'"
      exit 1
      ;;
    *)
      echo "Unknown suite '$arg'"
      exit 1
      ;;
  esac
done

if [ -z "$suites" ]; then
  suites="dart2js_native dart2js_extra language language_2 corelib corelib_2 html"
fi

repodir=$(cd $(dirname ${BASH_SOURCE[0]})/../../../../; pwd)
dart="out/ReleaseX64/dart"
update_script=$(dirname ${BASH_SOURCE[0]})/update_from_log.dart
binaries_dir=out/ReleaseX64

tmp=$(mktemp -d)

function update_suite {
  local suite=$1
  local runtime="d8"
  if [ "$suite" == "html" ]; then
    runtime="drt"
  fi
  echo -e "\nupdate suite: [32m$suite[0m"
  echo "  - minified tests"
  ./tools/test.py -m release -c dart2js -r $runtime --dart2js-batch \
      --use-sdk --minified --dart2js-with-kernel \
      $suite > $tmp/$suite-minified.txt
  $dart $update_script minified $tmp/$suite-minified.txt

  echo "  - host-checked tests"
  ./tools/test.py -m release -c dart2js -r $runtime --dart2js-batch \
    --host-checked \
    --dart2js-options="--platform-binaries=$binaries_dir" \
    --dart2js-with-kernel \
    $suite > $tmp/$suite-checked.txt
  $dart $update_script checked $tmp/$suite-checked.txt
}


pushd $repodir > /dev/null
./tools/build.py -m release create_sdk

for suite in $suites; do
  update_suite $suite
done

rm -rf $tmp
popd > /dev/null
