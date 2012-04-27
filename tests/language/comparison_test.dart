// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing comparison operators.

class Helper {
  static bool STRICT_EQ(a, b) {
    return a === b;
  }

  static bool STRICT_NE(a, b) {
    return a !== b;
  }

  static bool EQ(a, b) {
    return a == b;
  }

  static bool NE(a, b) {
    return a != b;
  }

  static bool LT(a, b) {
    return a < b;
  }

  static bool LE(a,b) {
    return a <= b;
  }

  static bool GT(a, b) {
    return a > b;
  }

  static bool GE(a, b) {
    return a >= b;
  }
}

class A {
  var b;

  A(x) : b = x { }
}

class ComparisonTest {
  static testMain() {
    var a = new A(0);
    var b = new A(1);
    Expect.equals(true, Helper.STRICT_EQ(a, a));
    Expect.equals(false, Helper.STRICT_EQ(a, b));
    Expect.equals(false, Helper.STRICT_EQ(b, a));
    Expect.equals(true, Helper.STRICT_EQ(b, b));

    Expect.equals(false, Helper.STRICT_NE(a, a));
    Expect.equals(true, Helper.STRICT_NE(a, b));
    Expect.equals(true, Helper.STRICT_NE(b, a));
    Expect.equals(false, Helper.STRICT_NE(b, b));

    Expect.equals(true, Helper.STRICT_EQ(false, false));
    Expect.equals(false, Helper.STRICT_EQ(false, true));
    Expect.equals(false, Helper.STRICT_EQ(true, false));
    Expect.equals(true, Helper.STRICT_EQ(true, true));

    Expect.equals(false, Helper.STRICT_NE(false, false));
    Expect.equals(true, Helper.STRICT_NE(false, true));
    Expect.equals(true, Helper.STRICT_NE(true, false));
    Expect.equals(false, Helper.STRICT_NE(true, true));

    Expect.equals(true, Helper.STRICT_EQ(false, false));
    Expect.equals(false, Helper.STRICT_EQ(false, true));
    Expect.equals(false, Helper.STRICT_EQ(true, false));
    Expect.equals(true, Helper.STRICT_EQ(true, true));

    Expect.equals(false, Helper.STRICT_NE(false, false));
    Expect.equals(true, Helper.STRICT_NE(false, true));
    Expect.equals(true, Helper.STRICT_NE(true, false));
    Expect.equals(false, Helper.STRICT_NE(true, true));

    Expect.equals(true, Helper.EQ(false, false));
    Expect.equals(false, Helper.EQ(false, true));
    Expect.equals(false, Helper.EQ(true, false));
    Expect.equals(true, Helper.EQ(true, true));

    Expect.equals(false, Helper.NE(false, false));
    Expect.equals(true, Helper.NE(false, true));
    Expect.equals(true, Helper.NE(true, false));
    Expect.equals(false, Helper.NE(true, true));

    Expect.equals(true, Helper.STRICT_EQ(-1, -1));
    Expect.equals(true, Helper.STRICT_EQ(0, 0));
    Expect.equals(true, Helper.STRICT_EQ(1, 1));
    Expect.equals(false, Helper.STRICT_EQ(-1, 0));
    Expect.equals(false, Helper.STRICT_EQ(-1, 1));
    Expect.equals(false, Helper.STRICT_EQ(0, 1));

    Expect.equals(false, Helper.STRICT_NE(-1, -1));
    Expect.equals(false, Helper.STRICT_NE(0, 0));
    Expect.equals(false, Helper.STRICT_NE(1, 1));
    Expect.equals(true, Helper.STRICT_NE(-1, 0));
    Expect.equals(true, Helper.STRICT_NE(-1, 1));
    Expect.equals(true, Helper.STRICT_NE(0, 1));

    Expect.equals(true, Helper.EQ(-1, -1));
    Expect.equals(true, Helper.EQ(0, 0));
    Expect.equals(true, Helper.EQ(1, 1));
    Expect.equals(false, Helper.EQ(-1, 0));
    Expect.equals(false, Helper.EQ(-1, 1));
    Expect.equals(false, Helper.EQ(0, 1));

    Expect.equals(false, Helper.NE(-1, -1));
    Expect.equals(false, Helper.NE(0, 0));
    Expect.equals(false, Helper.NE(1, 1));
    Expect.equals(true, Helper.NE(-1, 0));
    Expect.equals(true, Helper.NE(-1, 1));
    Expect.equals(true, Helper.NE(0, 1));

    Expect.equals(false, Helper.LT(-1, -1));
    Expect.equals(false, Helper.LT(0, 0));
    Expect.equals(false, Helper.LT(1, 1));
    Expect.equals(true, Helper.LT(-1, 0));
    Expect.equals(true, Helper.LT(-1, 1));
    Expect.equals(true, Helper.LT(0, 1));
    Expect.equals(false, Helper.LT(0, -1));
    Expect.equals(false, Helper.LT(1, -1));
    Expect.equals(false, Helper.LT(1, 0));

    Expect.equals(true, Helper.LE(-1, -1));
    Expect.equals(true, Helper.LE(0, 0));
    Expect.equals(true, Helper.LE(1, 1));
    Expect.equals(true, Helper.LE(-1, 0));
    Expect.equals(true, Helper.LE(-1, 1));
    Expect.equals(true, Helper.LE(0, 1));
    Expect.equals(false, Helper.LE(0, -1));
    Expect.equals(false, Helper.LE(1, -1));
    Expect.equals(false, Helper.LE(1, 0));

    Expect.equals(false, Helper.GT(-1, -1));
    Expect.equals(false, Helper.GT(0, 0));
    Expect.equals(false, Helper.GT(1, 1));
    Expect.equals(false, Helper.GT(-1, 0));
    Expect.equals(false, Helper.GT(-1, 1));
    Expect.equals(false, Helper.GT(0, 1));
    Expect.equals(true, Helper.GT(0, -1));
    Expect.equals(true, Helper.GT(1, -1));
    Expect.equals(true, Helper.GT(1, 0));

    Expect.equals(true, Helper.GE(-1, -1));
    Expect.equals(true, Helper.GE(0, 0));
    Expect.equals(true, Helper.GE(1, 1));
    Expect.equals(false, Helper.GE(-1, 0));
    Expect.equals(false, Helper.GE(-1, 1));
    Expect.equals(false, Helper.GE(0, 1));
    Expect.equals(true, Helper.GE(0, -1));
    Expect.equals(true, Helper.GE(1, -1));
    Expect.equals(true, Helper.GE(1, 0));

    // TODO(regis): Double literals are not yet canonicalized.
    // Expect.equals(true, Helper.STRICT_EQ(-1.0, -1.0));
    // Expect.equals(true, Helper.STRICT_EQ(0.0, 0.0));
    // Expect.equals(true, Helper.STRICT_EQ(1.0, 1.0));
    // Expect.equals(false, Helper.STRICT_EQ(-1.0, 0.0));
    // Expect.equals(false, Helper.STRICT_EQ(-1.0, 1.0));
    // Expect.equals(false, Helper.STRICT_EQ(0.0, 1.0));

    // Expect.equals(false, Helper.STRICT_NE(-1.0, -1.0));
    // Expect.equals(false, Helper.STRICT_NE(0.0, 0.0));
    // Expect.equals(false, Helper.STRICT_NE(1.0, 1.0));
    // Expect.equals(true, Helper.STRICT_NE(-1.0, 0.0));
    // Expect.equals(true, Helper.STRICT_NE(-1.0, 1.0));
    // Expect.equals(true, Helper.STRICT_NE(0.0, 1.0));

    Expect.equals(true, Helper.EQ(-1.0, -1.0));
    Expect.equals(true, Helper.EQ(0.0, 0.0));
    Expect.equals(true, Helper.EQ(1.0, 1.0));
    Expect.equals(false, Helper.EQ(-1.0, 0.0));
    Expect.equals(false, Helper.EQ(-1.0, 1.0));
    Expect.equals(false, Helper.EQ(0.0, 1.0));

    Expect.equals(false, Helper.NE(-1.0, -1.0));
    Expect.equals(false, Helper.NE(0.0, 0.0));
    Expect.equals(false, Helper.NE(1.0, 1.0));
    Expect.equals(true, Helper.NE(-1.0, 0.0));
    Expect.equals(true, Helper.NE(-1.0, 1.0));
    Expect.equals(true, Helper.NE(0.0, 1.0));

    Expect.equals(false, Helper.LT(-1.0, -1.0));
    Expect.equals(false, Helper.LT(0.0, 0.0));
    Expect.equals(false, Helper.LT(1.0, 1.0));
    Expect.equals(true, Helper.LT(-1.0, 0.0));
    Expect.equals(true, Helper.LT(-1.0, 1.0));
    Expect.equals(true, Helper.LT(0.0, 1.0));
    Expect.equals(false, Helper.LT(0.0, -1.0));
    Expect.equals(false, Helper.LT(1.0, -1.0));
    Expect.equals(false, Helper.LT(1.0, 0.0));

    Expect.equals(true, Helper.LE(-1.0, -1.0));
    Expect.equals(true, Helper.LE(0.0, 0.0));
    Expect.equals(true, Helper.LE(1.0, 1.0));
    Expect.equals(true, Helper.LE(-1.0, 0.0));
    Expect.equals(true, Helper.LE(-1.0, 1.0));
    Expect.equals(true, Helper.LE(0.0, 1.0));
    Expect.equals(false, Helper.LE(0.0, -1.0));
    Expect.equals(false, Helper.LE(1.0, -1.0));
    Expect.equals(false, Helper.LE(1.0, 0.0));

    Expect.equals(false, Helper.GT(-1.0, -1.0));
    Expect.equals(false, Helper.GT(0.0, 0.0));
    Expect.equals(false, Helper.GT(1.0, 1.0));
    Expect.equals(false, Helper.GT(-1.0, 0.0));
    Expect.equals(false, Helper.GT(-1.0, 1.0));
    Expect.equals(false, Helper.GT(0.0, 1.0));
    Expect.equals(true, Helper.GT(0.0, -1.0));
    Expect.equals(true, Helper.GT(1.0, -1.0));
    Expect.equals(true, Helper.GT(1.0, 0.0));

    Expect.equals(true, Helper.GE(-1.0, -1.0));
    Expect.equals(true, Helper.GE(0.0, 0.0));
    Expect.equals(true, Helper.GE(1.0, 1.0));
    Expect.equals(false, Helper.GE(-1.0, 0.0));
    Expect.equals(false, Helper.GE(-1.0, 1.0));
    Expect.equals(false, Helper.GE(0.0, 1.0));
    Expect.equals(true, Helper.GE(0.0, -1.0));
    Expect.equals(true, Helper.GE(1.0, -1.0));
    Expect.equals(true, Helper.GE(1.0, 0.0));

    Expect.equals(true, Helper.EQ(null, null));
    Expect.equals(false, Helper.EQ(null, "Str"));
    Expect.equals(true, Helper.NE(null, 2));
    Expect.equals(false, Helper.NE(null, null));

    Expect.equals(true, Helper.STRICT_EQ(null, null));
    Expect.equals(false, Helper.STRICT_EQ(null, "Str"));
    Expect.equals(true, Helper.STRICT_NE(null, 2));
    Expect.equals(false, Helper.STRICT_NE(null, null));

    Expect.equals(false, Helper.GT(1, 1.2));
    Expect.equals(true, Helper.GT(3, 1.2));
    Expect.equals(true, Helper.GT(2.0, 1));
    Expect.equals(false, Helper.GT(3.1, 4));

    Expect.equals(false, Helper.GE(1, 1.2));
    Expect.equals(true, Helper.GE(3, 1.2));
    Expect.equals(true, Helper.GE(2.0, 1));
    Expect.equals(false, Helper.GE(3.1, 4));
    Expect.equals(true, Helper.GE(2.0, 2));
    Expect.equals(true, Helper.GE(2, 2.0));

    Expect.equals(true, Helper.LT(1, 1.2));
    Expect.equals(false, Helper.LT(3, 1.2));
    Expect.equals(false, Helper.LT(2.0, 1));
    Expect.equals(true, Helper.LT(3.1, 4));

    Expect.equals(true, Helper.LE(1, 1.2));
    Expect.equals(false, Helper.LE(3, 1.2));
    Expect.equals(false, Helper.LE(2.0, 1));
    Expect.equals(true, Helper.LE(3.1, 4));
    Expect.equals(true, Helper.LE(2.0, 2));
    Expect.equals(true, Helper.LE(2, 2.0));

    // Bignums.
    Expect.equals(true, Helper.LE(0xF00000000005, 0xF00000000006));
    Expect.equals(true, Helper.LE(0xF00000000005, 0xF00000000005));
    Expect.equals(false, Helper.LE(0xF00000000006, 0xF00000000005));
    Expect.equals(true, Helper.LE(12, 0xF00000000005));
    Expect.equals(true, Helper.LE(12.2, 0xF00000000005));

    Expect.equals(true, Helper.EQ(4294967295, 4.294967295e9));
    Expect.equals(true, Helper.EQ(4.294967295e9, 4294967295));
    Expect.equals(false, Helper.EQ(4.294967295e9, 42));
    Expect.equals(false, Helper.EQ(42, 4.294967295e9));
    Expect.equals(false, Helper.EQ(4294967295, 42));
    Expect.equals(false, Helper.EQ(42, 4294967295));

    // Fractions & mixed
    Expect.equals(true, Helper.EQ(1.0, 1));
    Expect.equals(true, Helper.EQ(1.0, 1));
    Expect.equals(true, Helper.EQ(1, 1.0));
    Expect.equals(true, Helper.EQ(1, 1.0));
    Expect.equals(true, Helper.EQ(1.1, 1.1));
    Expect.equals(true, Helper.EQ(1.1, 1.1));
    Expect.equals(true, Helper.EQ(1.1, 1.1));

    Expect.equals(false, Helper.GT(1, 1.2));
    Expect.equals(true, Helper.GT(1.2, 1));
    Expect.equals(true, Helper.GT(1.2, 1.1));
    Expect.equals(true, Helper.GT(1.2, 1.1));
    Expect.equals(true, Helper.GT(1.2, 1.1));

    Expect.equals(true, Helper.LT(1, 1.2));
    Expect.equals(false, Helper.LT(1.2, 1));
    Expect.equals(false, Helper.LT(1.2, 1.1));
    Expect.equals(false, Helper.LT(1.2, 1.1));
    Expect.equals(false, Helper.LT(1.2, 1.1));

    Expect.equals(false, Helper.GE(1.1, 1.2));
    Expect.equals(false, Helper.GE(1.1, 1.2));
    Expect.equals(true, Helper.GE(1.2, 1.2));
    Expect.equals(true, Helper.GE(1.2, 1.2));

    // With non-number classes.
    Expect.equals(false, Helper.EQ(1, "eeny"));
    Expect.equals(false, Helper.EQ("meeny", 1));
    Expect.equals(false, Helper.EQ(1.1, "miny"));
    Expect.equals(false, Helper.EQ("moe", 1.1));
    Expect.equals(false, Helper.EQ(1.1, "catch"));
    Expect.equals(false, Helper.EQ("the", 1.1));

    // With null.
    Expect.equals(false, Helper.EQ(1, null));
    Expect.equals(false, Helper.EQ(null, 1));
    Expect.equals(false, Helper.EQ(1.1, null));
    Expect.equals(false, Helper.EQ(null, 1.1));
    Expect.equals(false, Helper.EQ(1.1, null));
    Expect.equals(false, Helper.EQ(null, 1.1));

    // TODO(srdjan): Clarify behaviour of greater/less comparisons
    // between numbers and non-numbers.
  }
}

main() {
  ComparisonTest.testMain();
}
