// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test mismatch in argument counts.

class ClosureCallWrongArgumentCountNegativeTest {
  static int melke(var f) {
    return f(1, 2, 3);
  }

  static void testMain() {
    kuh(int a, int b) {
      return a + b;
    }

    melke(kuh);
  }
}

main() {
  ClosureCallWrongArgumentCountNegativeTest.testMain();
}
