#!/usr/bin/env bash
# Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Analyze Dart code in the flutter/flutter repo.

set -ex

checkout=$(pwd)
dart=$checkout/out/ReleaseX64/dart-sdk/bin/dart
sdk=$checkout/out/ReleaseX64/dart-sdk
tmpdir=$(mktemp -d)
cd "$tmpdir"

git clone --single-branch -vv \
  https://dart.googlesource.com/external/github.com/flutter/flutter

cd flutter

bin/flutter config --no-analytics

bin/flutter update-packages

# Run a subset of the tests run by [flutter]/dev/bots/analyze.dart.
# Run only the tests that use the built dart analyzer.
bin/flutter analyze --flutter-repo --dart-sdk $sdk
bin/flutter analyze --flutter-repo --watch --benchmark --dart-sdk $sdk

mkdir gallery
$dart dev/tools/mega_gallery.dart --out gallery
pushd gallery
../bin/flutter analyze --watch --benchmark --dart-sdk $sdk
popd

# Test flutter's use of data-driven fixes.
$dart fix --suppress-analytics packages/flutter/test_fixes --compare-to-golden
