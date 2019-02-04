#!/usr/bin/env bash
#
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This script produces a patch to the Flutter Framework from the local
# uncommitted changes in the current engine checkout.
#
# Usage: src/third_party/dart/tools/patches/flutter-flutter/create.sh
# (run inside the root of a flutter engine checkout)

set -e

DIR=$(dirname -- "$(which -- "$0")")
. $DIR/../utils.sh

ensure_in_checkout_root

pinned_engine_version=$(get_pinned_flutter_engine_version)
patch=src/third_party/dart/tools/patches/flutter-flutter/$pinned_engine_version.patch
rm -f src/third_party/dart/tools/patches/flutter-flutter/*.patch
(cd flutter && git diff) > $patch
if [ ! -s $patch ]; then
  rm $patch
fi
