#!/usr/bin/env bash
#
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

die() {
  echo "$0: error: "\
       "This script must be run from the root of a flutter engine checkout "\
       "(containing src/flutter/ and flutter/)" >&2
  exit 1
}

ensure_in_checkout_root() {
  set -e
  if [ ! -e src/third_party/dart ]; then
    die
  fi

  if [ ! -e flutter ]; then
    die
  fi
}

get_pinned_dart_version() {
  pinned_dart_sdk=$(grep -E "'dart_revision':.*" src/flutter/DEPS |
                    sed -E "s/.*'([^']*)',/\1/")
  echo -n $pinned_dart_sdk
}

get_pinned_flutter_engine_version() {
  pinned_engine_version=$(cat flutter/bin/internal/engine.version | sed 's/[[:space:]]//')
  echo -n $pinned_engine_version
}
