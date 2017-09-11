#!/usr/bin/env bash
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Script to update the dart2js status lines for all tests running with the
# $dart2js_with_kernel test configuration.

repodir=$(cd $(dirname ${BASH_SOURCE[0]})/../../../../; pwd)
dart="out/ReleaseX64/dart"
update_script=$(dirname ${BASH_SOURCE[0]})/update_from_log.dart
sdk="out/ReleaseX64/dart-sdk"

tmp=$(mktemp -d)

function update_suite {
  local suite=$1
  echo -e "\nupdate suite: [32m$suite[0m"
  echo "  - minified tests"
  ./tools/test.py -m release -c dart2js -r d8 --dart2js-batch \
      --use-sdk --minified --dart2js-with-kernel \
      $suite > $tmp/$suite-minified.txt
  $dart $update_script minified $tmp/$suite-minified.txt

  echo "  - host-checked tests"
  ./tools/test.py -m release -c dart2js -r d8 --dart2js-batch --host-checked \
    --dart2js-options="--library-root=$sdk" --dart2js-with-kernel \
    $suite > $tmp/$suite-checked.txt
  $dart $update_script checked $tmp/$suite-checked.txt
}


pushd $repodir > /dev/null
./tools/build.py -m release create_sdk

if [[ $# -ge 1 ]]; then
  update_suite $1
else
  update_suite dart2js_native
  update_suite dart2js_extra
  update_suite language
  update_suite language_2
  update_suite corelib_2
fi

rm -rf $tmp
popd > /dev/null
