// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic properly handles external fields.  External
// fields are not promotable because they are effectively just getters; the
// language can't guarantee that they always return the same value.

abstract class C {
  external final int? _f1;
}

extension on C {
  external final int? _f2;
}

void testExternalFieldInClass(C c) {
  if (c._f1 != null) {
    var x = c._f1;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testExternalFieldInExtension(C c) {
  if (c._f2 != null) {
    var x = c._f2;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

main() {}
