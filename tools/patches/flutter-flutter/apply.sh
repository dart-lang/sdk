#!/usr/bin/env bash
#
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This script applies a patch, if available, to the Flutter Framework. Only a
# patch is applied for the particular engine.version the flutter framework is
# using.
#
# Usage: src/third_party/dart/tools/patches/flutter-flutter/apply.sh
# (run inside the root of a flutter checkout)

set -e

DIR=$(dirname -- "$(which -- "$0")")
. $DIR/../utils.sh

ensure_in_checkout_root

pinned_engine_version=$(get_pinned_flutter_engine_version)
patch=src/third_party/dart/tools/patches/flutter-flutter/${pinned_engine_version}.patch
if [ -e "$patch" ]; then
  (cd flutter && git apply ../$patch)
fi

pinned_dart_sdk=$(get_pinned_dart_version)
patch=src/third_party/dart/tools/patches/flutter-flutter/${pinned_dart_sdk}.patch
if [ -e "$patch" ]; then
  (cd flutter && git apply ../$patch)
fi
