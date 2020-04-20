#!/usr/bin/env bash
#
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# After you have checked out a flutter engine with the latest framework and the
# latest dart sdk, run this script to apply workarounds to the source code. It
# may patch up the source code so the three HEADs work together correctly.
#
# Usage: src/third_party/dart/tools/3xhead_flutter_hooks.sh
# (run inside the root of a flutter engine checkout)

set -e

DIR=$(dirname -- "$(which -- "$0")")
. $DIR/patches/utils.sh

ensure_in_checkout_root

# Apply patches to the Flutter Framework if needed.
src/third_party/dart/tools/patches/flutter-flutter/apply.sh

# Apply patches to the Flutter Engine if needed.
src/third_party/dart/tools/patches/flutter-engine/apply.sh
