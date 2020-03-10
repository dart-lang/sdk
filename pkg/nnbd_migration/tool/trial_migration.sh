#!/usr/bin/env bash
#
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

TRIAL_MIGRATION=`dirname "$0"`/trial_migration.dart

# Priority One, Group One, as defined at go/dart-null-safety-migration-order.
p1g1 () {
  for n in charcode collection logging path pedantic term_glyph typed_data ; do
    echo "-g https://dart.googlesource.com/${n}.git"
  done
  # Some packages do not have googlesource mirrors; use GitHub directly.
  echo "-g https://github.com/google/vector_math.dart.git"
  # SDK-only packages.
  echo "-p meta"
}


# The current "official" set of parameters for the trial_migration script.
set -x
dart --enable-asserts ${TRIAL_MIGRATION} \
  $(p1g1) \
  "$@"
