// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from tests/language/variable/variable_declaration_metadata_test.dart

const annotation = null;

use(x) => x;

test0() {
  for (var
  i1 = 0,
  @annotation // Error
  i2 = 0;;) {
    use(i1);
    use(i2);
    break;
  }
}

test2() {
  int
  i1 = 0,
  @annotation // Error
  i2 = 0;
  use(i1);
  use(i2);
}