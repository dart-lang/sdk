// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Tests weird cornercases of class Math.
// An exception is thrown either by the type checker (development mode) or by
// library (default mode).

class FakeNumber {
  const FakeNumber();
  void toDouble() {}
}

class MathTest {
  static bool testParseInt(x) {
    try {
      Math.parseInt(x);
      return true;
    } catch (var e) {
      print(e);
      return false;
    }
  }

  static bool testSqrt(x) {
    try {
      Math.sqrt(x);
      return true;
    } catch (var e) {
      print(e);
      return false;
    }
  }

  static void testMain() {
    Expect.equals(false, testParseInt(5));
    Expect.equals(false, testSqrt(const FakeNumber()));
  }
}
main() {
  MathTest.testMain();
}
