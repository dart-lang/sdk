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
    --with-fast-startup|--fast-startup)
      fast_startup=true
      ;;
    --strong)
      strong=true
      ;;
    --with-checked-mode|--checked-mode|--checked)
      checked_mode=true
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
  if [[ "$strong" == true ]]; then
    suites="language_2 corelib_2"
  else
    suites="dart2js_native dart2js_extra language corelib html"
  fi
fi

repodir=$(cd $(dirname ${BASH_SOURCE[0]})/../../../../; pwd)
dart="out/ReleaseX64/dart"
update_script=$(dirname ${BASH_SOURCE[0]})/update_from_log.dart
binaries_dir=out/ReleaseX64

tmp=$(mktemp -d)

function update_suite_with_flags {
  local name=$1
  local suite=$2
  shift 2
  local args=$@
  if [[ "$strong" == true ]]; then
    name="$name-strong"
    args="--strong $args"
  fi

  echo "  - $name tests"
  ./tools/test.py -m release -c dart2js -r $runtime --dart2js-batch \
      --dart2js-with-kernel $args $suite > $tmp/$suite-$name.txt
  echo $tmp/$suite-$name.txt
  $dart $update_script $name $tmp/$suite-$name.txt
}

function update_suite {
  local suite=$1
  local runtime="d8"
  if [ "$suite" == "html" ]; then
    runtime="drt"
  fi
  echo -e "\nupdate suite: [32m$suite[0m"
  update_suite_with_flags minified $suite "--minified --use-sdk"
  update_suite_with_flags host-checked $suite "--host-checked"
  if [ "$fast_startup" = true ]; then
    update_suite_with_flags fast-startup $suite "--fast-startup"
  fi
  if [ "$checked_mode" = true ]; then
    update_suite_with_flags checked-mode $suite "--checked"
  fi
}


pushd $repodir > /dev/null
./tools/build.py -m release create_sdk

for suite in $suites; do
  update_suite $suite
done

rm -rf $tmp
popd > /dev/null
