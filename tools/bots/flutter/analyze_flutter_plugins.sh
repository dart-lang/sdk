#!/usr/bin/env bash

# Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Analyze Dart code in the flutter/plugins repo.

set -e

checkout=$(pwd)
export PATH=$checkout/out/ReleaseX64/dart-sdk/bin:$PATH
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

# get the flutter/plugins repo
git clone --single-branch -vv https://github.com/flutter/plugins
cd plugins

# validate the tool's source
(cd script/tool; dart pub get)
(cd script/tool; dart analyze --fatal-infos)

# Invoke the repo's analysis script.
./script/tool_runner.sh analyze \
  --analysis-sdk $sdk \
  --custom-analysis=script/configs/custom_analysis.yaml
