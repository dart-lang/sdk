#!/usr/bin/env bash
#
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This script produces a patch to the Flutter Engine from the local uncommitted
# changes in the current engine checkout. It is named after the Dart SDK
# revision the engine is currently pinned to. It's meant to be consumed by the
# apply.sh script next to this script. Any existing patches are removed, as they
# are assumed to not be relevant anymore. If there are no uncommited changes in
# the local engine checkout, then no patch is produced.
#
# Usage: src/third_party/dart/tools/patches/flutter-engine/create.sh
# (run inside the root of a flutter engine checkout)

set -e

DIR=$(dirname -- "$(which -- "$0")")
. $DIR/../utils.sh

ensure_in_checkout_root

pinned_dart_sdk=$(get_pinned_dart_version)
patch=src/third_party/dart/tools/patches/flutter-engine/$pinned_dart_sdk.patch
rm -f src/third_party/dart/tools/patches/flutter-engine/*.patch
(cd src/flutter && git diff) > $patch
if [ ! -s $patch ]; then
  rm $patch
fi
