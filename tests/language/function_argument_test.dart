// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for function passing.

class FunctionArgumentTest {
  static testMe(Function f) {
    return f();
  }

  static void testMain() {
    Expect.equals(42, testMe(() { return 42; }));
    Expect.equals(314, testMe(f() { return 314; }));
    // Test another unnamed function.
    Expect.equals(99, testMe(() { return 99; }));
  }
}

main() {
  FunctionArgumentTest.testMain();
}
