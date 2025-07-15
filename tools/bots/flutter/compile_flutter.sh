#!/usr/bin/env bash
# Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Compile flutter tests with a locally built SDK.

set -ex

prepareOnly=false
leakTest=false
weeklyTest=false

REMAINING_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --prepareOnly|--prepare-only|--prepare_only)
      prepareOnly=true
      shift
      ;;
    --leakTest|--leak-test|--leak_test)
      leakTest=true
      shift
      ;;
    --weeklyTest|--weekly-test|--weekly_test)
      weeklyTest=true
      shift
      ;;
    *)
      REMAINING_ARGS+=("$1")
      shift
      ;;
  esac
done
# Restore remaining arguments.
set -- "${REMAINING_ARGS[@]}"

if $prepareOnly; then
  echo "Will prepare only!"
elif $leakTest; then
  echo "Will run leak test"
fi

checkout=$(pwd)
dart=$checkout/out/ReleaseX64/dart-sdk/bin/dart
sdk=$checkout/out/ReleaseX64/dart-sdk
tmpdir=$(mktemp -d)
cleanup() {
  if ! $prepareOnly; then
    rm -rf "$tmpdir"
  fi
}
trap cleanup EXIT HUP INT QUIT TERM PIPE
pushd "$tmpdir"

git clone --single-branch -vv \
    https://dart.googlesource.com/external/github.com/flutter/flutter

pushd flutter
bin/flutter config --no-analytics
bin/flutter update-packages
pushd engine
pushd src/flutter/third_party
ln -s $checkout dart
popd  # src/flutter/third_party

# This script doesn't seem to work anymore.
./src/flutter/third_party/dart/tools/patches/flutter-engine/apply.sh || true

popd  # engine
popd  # flutter

mkdir flutter_patched_sdk

$checkout/tools/sdks/dart-sdk/bin/dart \
    --packages=$checkout/.dart_tool/package_config.json \
    $checkout/pkg/front_end/tool/compile_platform.dart \
    dart:core \
    -Ddart.vm.product=false \
    -Ddart.isVM=true \
    --single-root-scheme=org-dartlang-sdk \
    --single-root-base=$checkout/ \
    org-dartlang-sdk:///sdk/lib/libraries.json \
    vm_outline.dill \
    vm_platform.dill \
    vm_outline.dill

$checkout/tools/sdks/dart-sdk/bin/dart \
    --packages=$checkout/.dart_tool/package_config.json \
    $checkout/pkg/front_end/tool/compile_platform.dart \
    --target=flutter \
    dart:core \
    --single-root-scheme=org-dartlang-sdk \
    --single-root-base=flutter/engine/src \
    org-dartlang-sdk:///flutter/lib/snapshot/libraries.json \
    vm_outline.dill \
    flutter_patched_sdk/platform_strong.dill \
    flutter_patched_sdk/outline_strong.dill

popd  # tmpdir

if $prepareOnly; then
  echo "Preparations complete!"
  echo "Flutter is now in $tmpdir/flutter and the patched sdk in $tmpdir/flutter_patched_sdk"
  echo "You can run the test with $dart --enable-asserts pkg/frontend_server/test/frontend_server_flutter.dart --flutterDir=$tmpdir/flutter --flutterPlatformDir=$tmpdir/flutter_patched_sdk"
elif $leakTest; then
  $dart \
      --enable-asserts \
      pkg/front_end/test/flutter_gallery_leak_tester.dart \
      --path=$tmpdir
elif $weeklyTest; then
  $dart \
      --enable-asserts \
      pkg/front_end/test/weekly_tester.dart \
      --path=$tmpdir \
      $@
else
  $dart \
      --enable-asserts \
      pkg/frontend_server/test/frontend_server_flutter_suite.dart \
      -v \
      --flutterDir=$tmpdir/flutter \
      --flutterPlatformDir=$tmpdir/flutter_patched_sdk \
      $@
fi
