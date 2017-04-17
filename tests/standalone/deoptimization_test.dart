// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test deoptimization.

import "package:expect/expect.dart";

class SmiCompares {
  // Test deoptimization when one argument is known to be Smi.
  static bool smiCompareLessThan2(a) {
    return a < 2;
  }

  // Test deoptimization when one argument is known to be Smi.
  static bool smiCompareGreaterThan2(a) {
    return 2 < a;
  }

  // Test deoptimization when both arguments unknown.
  static bool smiCompareLessThan(a, b) {
    return a < b;
  }

  // Test deoptimization when both arguments unknown.
  static bool smiCompareGreaterThan(a, b) {
    return a > b;
  }

  static smiComparesTest() {
    for (int i = 0; i < 2000; i++) {
      Expect.equals(true, smiCompareLessThan2(1));
      Expect.equals(false, smiCompareLessThan2(3));
      Expect.equals(false, smiCompareGreaterThan2(1));
      Expect.equals(true, smiCompareGreaterThan2(3));
      Expect.equals(true, smiCompareLessThan(1, 2));
      Expect.equals(false, smiCompareGreaterThan(1, 2));
    }
    // Deoptimize by passing a double instead of Smi
    Expect.equals(true, smiCompareLessThan2(1.0));
    Expect.equals(false, smiCompareGreaterThan2(1.0));
    Expect.equals(true, smiCompareLessThan(1.0, 2));
    Expect.equals(false, smiCompareGreaterThan(1, 2.0));
  }
}

class SmiBinop {
  static subWithLiteral(a) {
    return a - 1;
  }

  static void smiBinopTest() {
    for (int i = 0; i < 2000; i++) {
      Expect.equals(2, subWithLiteral(3));
    }
    // Deoptimize.
    Expect.equals(2.0, subWithLiteral(3.0));
  }

  static mul(x) {
    return x * 1024;
  }

  static void smiBinopOverflowTest() {
    final int big = 536870912;
    for (int i = 0; i < 2000; i++) {
      Expect.equals(1024, mul(1));
    }
    // Deoptimize by overflow.
    Expect.equals(1024 * big, mul(big));
  }
}

class ObjectsEquality {
  static bool compareEqual(a, b) {
    return a == b;
  }

  static bool compareNotEqual(a, b) {
    return a != b;
  }

  // Use only Object.==.
  static void objectsEqualityTest() {
    var a = new ObjectsEquality();
    var b = new ObjectsEquality();
    final nan = 0.0 / 0.0;
    for (int i = 0; i < 1000; i++) {
      Expect.equals(true, compareEqual(a, a));
      Expect.equals(true, compareEqual(null, null));
      Expect.equals(false, compareEqual(null, a));
      Expect.equals(false, compareEqual(a, null));
      Expect.equals(true, compareEqual(b, b));
      Expect.equals(false, compareEqual(a, b));

      Expect.equals(false, compareNotEqual(a, a));
      Expect.equals(false, compareNotEqual(null, null));
      Expect.equals(true, compareNotEqual(null, a));
      Expect.equals(true, compareNotEqual(a, null));
      Expect.equals(false, compareNotEqual(b, b));
      Expect.equals(true, compareNotEqual(a, b));
    }
    var c = new SmiBinop();
    // Deoptimize.
    Expect.equals(true, compareEqual(c, c));
    Expect.equals(false, compareEqual(c, null));
    Expect.equals(false, compareNotEqual(c, c));
    Expect.equals(true, compareNotEqual(c, null));
  }
}

class DeoptimizationTest {
  static foo(a, b) {
    return a - b;
  }

  static test1() {
    for (int i = 0; i < 2000; i++) {
      Expect.equals(2, foo(3, 1)); // <-- Optimizes 'foo',
    }
    Expect.equals(2.2, foo(1.2, -1.0)); // <-- Deoptimizes 'foo'.
    for (int i = 0; i < 10000; i++) {
      Expect.equals(2, foo(3, 1)); // <-- Optimizes 'foo'.
    }
    Expect.equals(2.2, foo(1.2, -1)); // <-- Deoptimizes 'foo'.
  }

  static moo(n) {
    return ++n;
  }

  static test2() {
    for (int i = 0; i < 2000; i++) {
      Expect.equals(4, moo(3)); // <-- Optimizes 'moo',
    }
    Expect.equals(2.2, moo(1.2)); // <-- Deoptimizes 'moo'.
    for (int i = 0; i < 10000; i++) {
      Expect.equals(4, moo(3)); // <-- Optimizes 'moo'.
    }
    Expect.equals(2.2, moo(1.2)); // <-- Deoptimizes 'moo'.
  }

  static test3() {
    for (int i = 0; i < 2000; i++) {
      Expect.equals(2.0, foo(3.0, 1.0)); // <-- Optimizes 'foo',
    }
    Expect.equals(2, foo(1, -1)); // <-- Deoptimizes 'foo'.
    for (int i = 0; i < 2000; i++) {
      Expect.equals(2.0, foo(3.0, 1.0)); // <-- Optimizes 'foo',
    }
    Expect.equals(2.2, moo(1.2)); // <-- Deoptimizes 'moo'.
  }

  static bool compareInt(a, b) {
    return a < b;
  }

  static bool compareDouble(a, b) {
    return a < b;
  }

  static test4() {
    for (int i = 0; i < 2000; i++) {
      Expect.equals(true, compareInt(1, 2));
      Expect.equals(true, compareDouble(1.0, 2.0));
    }
    // Trigger deoptimization in compareInt and compareDouble.
    Expect.equals(true, compareInt(1, 2.0));
    Expect.equals(true, compareDouble(1.0, 2));
  }

  static smiRightShift() {
    int ShiftRight(int a, int b) {
      return a >> b;
    }

    for (int i = 0; i < 2000; i++) {
      var r = ShiftRight(10, 2);
      Expect.equals(2, r);
    }
    // ShiftRight is optimized.
    Expect.equals(0, ShiftRight(10, 64));
    // Deoptimize ShiftRight because 'a' is a Mint.
    var mint = 1 << 63;
    Expect.equals(1 << 3, ShiftRight(mint, 60));
  }

  static doubleUnary() {
    num unary(num a) {
      return -a;
    }

    for (int i = 0; i < 2000; i++) {
      var r = unary(2.0);
      Expect.equals(-2.0, r);
    }
    var r = unary(5);
    Expect.equals(-5, r);
  }

  static void testMain() {
    test1();
    test2();
    test3();
    test4();
    SmiCompares.smiComparesTest();
    SmiBinop.smiBinopTest();
    SmiBinop.smiBinopOverflowTest();
    ObjectsEquality.objectsEqualityTest();
    smiRightShift();
    doubleUnary();
  }
}

main() {
  DeoptimizationTest.testMain();
}
