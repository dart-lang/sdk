// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/operator/unsupported_test.dart

// Test handling of unsupported operators.

library unsupported_operators;

class C {
  m() {
    print(super === null); // Error
    print(super !== null); // Error
  }
}

void foo() {
  new C().m();
  new C().m();
  print("foo" === null); // Error
  print("foo" !== null); // Error
}
