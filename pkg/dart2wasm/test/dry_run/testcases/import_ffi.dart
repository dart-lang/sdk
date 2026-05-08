// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DRY_RUN: 16, dart:ffi
import 'dart:ffi';

void main() {}

// Regression test for https://github.com/dart-lang/sdk/issues/62626.
// `dart:ffi` transformations crash on this, and we should instead skip the
// transformations if `dart:ffi` is not importable (skipping the crash).
@Native<Int>()
external int field;
