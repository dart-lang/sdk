#!/bin/sh
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
if [ ! -e src/third_party/dart ]; then
  echo "$0: error: "\
       "This script must be run from the root of a flutter engine checkout" >&2
  exit 1
fi

# Apply patches to the Flutter Engine if needed.
src/third_party/dart/tools/patches/flutter-engine/apply.sh
