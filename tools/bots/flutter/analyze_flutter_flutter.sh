#!/usr/bin/env bash
# Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Analyze Dart code in the flutter/flutter repo.

set -e

checkout=$(pwd)
dart=$checkout/out/ReleaseX64/dart-sdk/bin/dart
sdk=$checkout/out/ReleaseX64/dart-sdk
tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT HUP INT QUIT TERM PIPE
cd "$tmpdir"

git clone --single-branch -vv \
  https://dart.googlesource.com/external/github.com/flutter/flutter

cd flutter

bin/flutter config --no-analytics

pinned_dart_sdk=$(cat bin/cache/dart-sdk/revision)
patch=$checkout/tools/patches/flutter-engine/${pinned_dart_sdk}.flutter.patch
if [ -e "$patch" ]; then
  git apply $patch
fi

bin/flutter update-packages

$dart --enable-asserts dev/bots/analyze.dart --dart-sdk $sdk
