#!/usr/bin/env bash
# Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Analyze Dart code in various Flutter repos.

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

analyze_engine() {
  echo Analyzing Flutter engine lib/web_ui...
  pushd flutter/engine/src/flutter/lib/web_ui

  $dart pub get
  $dart analyze --suppress-analytics --fatal-infos

  popd
}

analyze_flutter_sdk() {
  echo Configuring Flutter SDK and updating packages...
  pushd flutter
  bin/flutter config --no-analytics
  bin/flutter update-packages

  # Run a subset of the tests run by [flutter]/dev/bots/analyze.dart.
  # Run only the tests that use the built dart analyzer.
  echo Analyzing Flutter SDK...
  bin/flutter analyze --flutter-repo --dart-sdk $sdk
  bin/flutter analyze --flutter-repo --watch --benchmark --dart-sdk $sdk

  echo Analyzing mega gallery...
  mkdir gallery
  $dart dev/tools/mega_gallery.dart --out gallery
  pushd gallery
  ../bin/flutter analyze --watch --benchmark --dart-sdk $sdk
  popd

  echo Testing data-driven fixes...
  $dart fix --suppress-analytics packages/flutter/test_fixes --compare-to-golden

  popd
}

analyze_flutter_packages() {
  export PATH="$PATH":"$tmpdir/flutter/bin"
  flutter --version

  echo Cloning flutter/packages/...
  git clone --single-branch -vv https://github.com/flutter/packages
  pushd packages

  echo "Validating the tool's source"
  (cd script/tool; dart pub --suppress-analytics get)
  (cd script/tool; dart analyze --suppress-analytics --fatal-infos)

  echo Analyzing flutter/packages...
  # Invoke the repo's analysis script.
  # Use --downgrade to avoid potential breakage from transitive
  # dependency publishing. See
  # https://github.com/flutter/flutter/issues/129633
  dart run script/tool/bin/flutter_plugin_tools.dart analyze \
    --downgrade \
    --analysis-sdk $sdk \
    --custom-analysis=script/configs/custom_analysis.yaml \
    --base-branch=main

  popd
}

echo Cloning flutter/flutter...
git clone --single-branch -vv \
  https://dart.googlesource.com/external/github.com/flutter/flutter

analyze_engine
analyze_flutter_sdk
analyze_flutter_packages
