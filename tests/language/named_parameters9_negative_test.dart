// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.


class NamedParameters9NegativeTest {

  static int f(a [b = 42]) => b;  // Missing comma.

  static testMain() {
    try {
      f(10, 25);
    } catch (var e) {
      // This is a negative test that should not compile.
      // If it runs due to a bug, catch and ignore exceptions.
    }
  }
}

main() {
  NamedParameters9NegativeTest.testMain();
}
