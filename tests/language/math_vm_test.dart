// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Tests that the VM does not crash on weird corner cases of class Math.
// VMOptions=--optimization_counter_threshold=100

#import('dart:math');

class FakeNumber {
  const FakeNumber();
  void toDouble() {}
}

class MathTest {
  static bool testParseInt(x) {
    try {
      parseInt(x);  // Expects string.
      return true;
    } catch (var e) {
      return false;
    }
  }

  static bool testSqrt(x) {
    try {
      sqrt(x);  // Expects number.
      return true;
    } catch (var e) {
      return false;
    }
  }

  static void testMain() {
    Expect.equals(false, testParseInt(5));
    Expect.equals(false, testSqrt(const FakeNumber()));
  }
}
main() {
  for (int i = 0; i < 200; i++) {
    MathTest.testMain();
  }
}
