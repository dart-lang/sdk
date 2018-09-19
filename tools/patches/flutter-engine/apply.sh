#!/bin/sh
#
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# When in a Flutter Engine checkout, this script checks what version of the Dart
# SDK the engine is pinned to, and patches the engine if there is a known patch
# that needs to be applied on the next Dart SDK roll in the engine.
#
# This script is meant to be used by 3xHEAD CI infrastructure, allowing
# incompatible changes to be made to the Dart SDK requiring a matching change
# to the Flutter Engine, without breaking the CI. The patch is associated with
# the Dart SDK version the engine is pinned so. When the engine rolls its SDK,
# then it stops applying patches atomically as there isn't a patch available yet
# for the new roll.
#
# Usage: src/third_party/dart/tools/patches/flutter-engine/apply.sh
# (run inside the root of a flutter engine checkout)

set -e
if [ ! -e src/third_party/dart ]; then
  echo "$0: error: "\
       "This script must be run from the root of a flutter engine checkout" >&2
  exit 1
fi
pinned_dart_sdk=$(grep -E "'dart_revision':.*" src/flutter/DEPS |
                  sed -E "s/.*'([^']*)',/\1/")
need_runhooks=false
patch=src/third_party/dart/tools/patches/flutter-engine/${pinned_dart_sdk}.flutter.patch
if [ -e "$patch" ]; then
  (cd flutter && git apply ../$patch)
  need_runhooks=true
fi
patch=src/third_party/dart/tools/patches/flutter-engine/${pinned_dart_sdk}.patch
if [ -e "$patch" ]; then
  (cd src/flutter && git apply ../../$patch)
  need_runhooks=true
fi
if [ $need_runhooks = true ]; then
  gclient runhooks
fi
