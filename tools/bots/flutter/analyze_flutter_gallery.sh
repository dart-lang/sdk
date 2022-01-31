#!/usr/bin/env bash
# Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Analyze Dart code in the flutter/gallery repo.

set -ex

checkout=$(pwd)
dart=$checkout/out/ReleaseX64/dart-sdk/bin/dart
sdk=$checkout/out/ReleaseX64/dart-sdk
tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT HUP INT QUIT TERM PIPE
cd "$tmpdir"

# install flutter
git clone --single-branch -vv https://github.com/flutter/flutter
export PATH="$PATH":"$tmpdir/flutter/bin"
flutter --version

git clone --single-branch -vv \
  https://dart.googlesource.com/external/github.com/flutter/gallery

cd gallery

# analyze
echo Analyzing...

flutter packages get
$dart analyze --fatal-infos
