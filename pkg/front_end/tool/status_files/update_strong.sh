#!/usr/bin/env bash
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Script to update the dartk/dartkp status lines for all tests running with the
# $strong configuration for the language_2, corelib_2, lib_2, and standalone_2
# suites.

suites=
mode="release"
extra_flags=""
message=

for arg in "$@"; do
  case $arg in
    language_2|corelib_2|lib_2|standalone_2)
      suites="$suites $arg"
      ;;
    --debug)
      mode="debug"
      ;;
    -j*)
      extra_flags="$arg"
      ;;
    -h|--help)
      echo "$0 [options] <suites>"
      echo "where: "
      echo "  <suites>        a space separated list of suites."
      echo "      Currently only language_2, corelib_2, lib_2, and standalone_2 "
      echo "      are supported. Defaults to all."
      echo ""
      echo "  --debug         update the status in \$mode == debug."
      echo ""
      echo "  --message='...' include the given message as comments on updated status lines."
      echo ""
      echo "  -h | --help     this help message."
      exit 0
      ;;
    --message=*)
      message="${arg/--message=/}"
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
  suites="language_2 corelib_2 lib_2 standalone_2"
fi

repodir=$(cd $(dirname ${BASH_SOURCE[0]})/../../../../; pwd)
dart="out/ReleaseX64/dart"
update_script=$(dirname ${BASH_SOURCE[0]})/update_from_log.dart
binaries_dir=out/ReleaseX64

tmp=$(mktemp -d /tmp/tmp.logs-XXXXXX)

function update_suite {
  local suite=$1
  local flags="--strong $extra_flags"
  local suffix=""
  if [ "$mode" == "debug" ]; then
    flags="$flags"
    suffix="-debug"
  fi

  echo -e "\nupdate suite: [32m$suite[0m"

  echo "  - dark $mode tests"
  ./tools/test.py -m $mode -c dartk -r vm $flags \
      $suite > $tmp/$suite-dartk$mode.txt
  $dart $update_script dartk$suffix $tmp/$suite-dartk$mode.txt "$message"

  echo "  - darkp $mode tests"
  ./tools/test.py -m $mode -c dartkp -r dart_precompiled $flags \
      $suite > $tmp/$suite-dartkp$mode.txt
  $dart $update_script dartkp$suffix $tmp/$suite-dartkp$mode.txt "$message"
}

pushd $repodir > /dev/null
./tools/build.py -m $mode runtime_kernel dart_precompiled_runtime

for suite in $suites; do
  update_suite $suite
done

rm -rf $tmp
popd > /dev/null
