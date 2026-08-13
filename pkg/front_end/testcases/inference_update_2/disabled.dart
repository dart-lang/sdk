// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion doesn't happen when the feature is disabled.

// @dart=2.18

abstract class C {
  final int? _privateFinalField;

  C(int? i) : _privateFinalField = i;
}

void testPrivateFinalField(C c) {
  if (c._privateFinalField != null) {
    var x = c._privateFinalField;
    // `x` has type `int?` so this is ok
    x = null;
  }
}
