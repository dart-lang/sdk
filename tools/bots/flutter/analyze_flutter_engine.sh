#!/usr/bin/env bash
# Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Analyze Dart code in the flutter/engine repo.

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
  https://dart.googlesource.com/external/github.com/flutter/engine

cd engine

# analyze lib/web_ui
echo Analyzing lib/web_ui...
pushd lib/web_ui

$dart pub get
$dart analyze --fatal-infos

popd
