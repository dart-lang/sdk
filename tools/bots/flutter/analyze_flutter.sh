#!/usr/bin/env bash
# Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# Runs flutter's analyze tests with a locally built SDK.
set -e

dart=$(pwd)/tools/sdks/dart-sdk/bin/dart
sdk=$(pwd)/out/ReleaseX64/dart-sdk
tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT HUP INT QUIT TERM PIPE
cd "$tmpdir"

git clone https://chromium.googlesource.com/external/github.com/flutter/flutter
cd flutter
bin/flutter config --no-analytics
bin/flutter update-packages
$dart dev/bots/analyze.dart --dart-sdk $sdk