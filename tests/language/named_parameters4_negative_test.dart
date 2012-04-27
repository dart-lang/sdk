// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.


class NamedParameters4NegativeTest {

  static int F31(int a, [int b = 20, int c = 30]) {
    return 100*(100*a + b) + c;
  }

  static testMain() {
    try {
      F31(10, b:25, b:35);  // Duplicate named argument.
    } catch (var e) {
      // This is a negative test that should not compile.
      // If it runs due to a bug, catch and ignore exceptions.
    }
  }
}

main() {
  NamedParameters4NegativeTest.testMain();
}
