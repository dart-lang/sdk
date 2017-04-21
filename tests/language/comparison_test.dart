// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing comparison operators.

import "package:expect/expect.dart";

class Helper {
  static bool STRICT_EQ(a, b) {
    return identical(a, b);
  }

  static bool STRICT_NE(a, b) {
    return !identical(a, b);
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

  static bool LE(a, b) {
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

  A(x) : b = x {}
}

class ComparisonTest {
  static testMain() {
    var a = new A(0);
    var b = new A(1);
    Expect.isTrue(Helper.STRICT_EQ(a, a));
    Expect.isFalse(Helper.STRICT_EQ(a, b));
    Expect.isFalse(Helper.STRICT_EQ(b, a));
    Expect.isTrue(Helper.STRICT_EQ(b, b));

    Expect.isFalse(Helper.STRICT_NE(a, a));
    Expect.isTrue(Helper.STRICT_NE(a, b));
    Expect.isTrue(Helper.STRICT_NE(b, a));
    Expect.isFalse(Helper.STRICT_NE(b, b));

    Expect.isTrue(Helper.STRICT_EQ(false, false));
    Expect.isFalse(Helper.STRICT_EQ(false, true));
    Expect.isFalse(Helper.STRICT_EQ(true, false));
    Expect.isTrue(Helper.STRICT_EQ(true, true));

    Expect.isFalse(Helper.STRICT_NE(false, false));
    Expect.isTrue(Helper.STRICT_NE(false, true));
    Expect.isTrue(Helper.STRICT_NE(true, false));
    Expect.isFalse(Helper.STRICT_NE(true, true));

    Expect.isTrue(Helper.STRICT_EQ(false, false));
    Expect.isFalse(Helper.STRICT_EQ(false, true));
    Expect.isFalse(Helper.STRICT_EQ(true, false));
    Expect.isTrue(Helper.STRICT_EQ(true, true));

    Expect.isFalse(Helper.STRICT_NE(false, false));
    Expect.isTrue(Helper.STRICT_NE(false, true));
    Expect.isTrue(Helper.STRICT_NE(true, false));
    Expect.isFalse(Helper.STRICT_NE(true, true));

    Expect.isTrue(Helper.EQ(false, false));
    Expect.isFalse(Helper.EQ(false, true));
    Expect.isFalse(Helper.EQ(true, false));
    Expect.isTrue(Helper.EQ(true, true));

    Expect.isFalse(Helper.NE(false, false));
    Expect.isTrue(Helper.NE(false, true));
    Expect.isTrue(Helper.NE(true, false));
    Expect.isFalse(Helper.NE(true, true));

    Expect.isTrue(Helper.STRICT_EQ(-1, -1));
    Expect.isTrue(Helper.STRICT_EQ(0, 0));
    Expect.isTrue(Helper.STRICT_EQ(1, 1));
    Expect.isFalse(Helper.STRICT_EQ(-1, 0));
    Expect.isFalse(Helper.STRICT_EQ(-1, 1));
    Expect.isFalse(Helper.STRICT_EQ(0, 1));

    Expect.isFalse(Helper.STRICT_NE(-1, -1));
    Expect.isFalse(Helper.STRICT_NE(0, 0));
    Expect.isFalse(Helper.STRICT_NE(1, 1));
    Expect.isTrue(Helper.STRICT_NE(-1, 0));
    Expect.isTrue(Helper.STRICT_NE(-1, 1));
    Expect.isTrue(Helper.STRICT_NE(0, 1));

    Expect.isTrue(Helper.EQ(-1, -1));
    Expect.isTrue(Helper.EQ(0, 0));
    Expect.isTrue(Helper.EQ(1, 1));
    Expect.isFalse(Helper.EQ(-1, 0));
    Expect.isFalse(Helper.EQ(-1, 1));
    Expect.isFalse(Helper.EQ(0, 1));

    Expect.isFalse(Helper.NE(-1, -1));
    Expect.isFalse(Helper.NE(0, 0));
    Expect.isFalse(Helper.NE(1, 1));
    Expect.isTrue(Helper.NE(-1, 0));
    Expect.isTrue(Helper.NE(-1, 1));
    Expect.isTrue(Helper.NE(0, 1));

    Expect.isFalse(Helper.LT(-1, -1));
    Expect.isFalse(Helper.LT(0, 0));
    Expect.isFalse(Helper.LT(1, 1));
    Expect.isTrue(Helper.LT(-1, 0));
    Expect.isTrue(Helper.LT(-1, 1));
    Expect.isTrue(Helper.LT(0, 1));
    Expect.isFalse(Helper.LT(0, -1));
    Expect.isFalse(Helper.LT(1, -1));
    Expect.isFalse(Helper.LT(1, 0));

    Expect.isTrue(Helper.LE(-1, -1));
    Expect.isTrue(Helper.LE(0, 0));
    Expect.isTrue(Helper.LE(1, 1));
    Expect.isTrue(Helper.LE(-1, 0));
    Expect.isTrue(Helper.LE(-1, 1));
    Expect.isTrue(Helper.LE(0, 1));
    Expect.isFalse(Helper.LE(0, -1));
    Expect.isFalse(Helper.LE(1, -1));
    Expect.isFalse(Helper.LE(1, 0));

    Expect.isFalse(Helper.GT(-1, -1));
    Expect.isFalse(Helper.GT(0, 0));
    Expect.isFalse(Helper.GT(1, 1));
    Expect.isFalse(Helper.GT(-1, 0));
    Expect.isFalse(Helper.GT(-1, 1));
    Expect.isFalse(Helper.GT(0, 1));
    Expect.isTrue(Helper.GT(0, -1));
    Expect.isTrue(Helper.GT(1, -1));
    Expect.isTrue(Helper.GT(1, 0));

    Expect.isTrue(Helper.GE(-1, -1));
    Expect.isTrue(Helper.GE(0, 0));
    Expect.isTrue(Helper.GE(1, 1));
    Expect.isFalse(Helper.GE(-1, 0));
    Expect.isFalse(Helper.GE(-1, 1));
    Expect.isFalse(Helper.GE(0, 1));
    Expect.isTrue(Helper.GE(0, -1));
    Expect.isTrue(Helper.GE(1, -1));
    Expect.isTrue(Helper.GE(1, 0));

    Expect.isTrue(Helper.STRICT_EQ(-1.0, -1.0));
    Expect.isTrue(Helper.STRICT_EQ(0.0, 0.0));
    Expect.isTrue(Helper.STRICT_EQ(1.0, 1.0));
    Expect.isFalse(Helper.STRICT_EQ(-1.0, 0.0));
    Expect.isFalse(Helper.STRICT_EQ(-1.0, 1.0));
    Expect.isFalse(Helper.STRICT_EQ(0.0, 1.0));

    Expect.isFalse(Helper.STRICT_NE(-1.0, -1.0));
    Expect.isFalse(Helper.STRICT_NE(0.0, 0.0));
    Expect.isFalse(Helper.STRICT_NE(1.0, 1.0));
    Expect.isTrue(Helper.STRICT_NE(-1.0, 0.0));
    Expect.isTrue(Helper.STRICT_NE(-1.0, 1.0));
    Expect.isTrue(Helper.STRICT_NE(0.0, 1.0));

    Expect.isTrue(Helper.EQ(-1.0, -1.0));
    Expect.isTrue(Helper.EQ(0.0, 0.0));
    Expect.isTrue(Helper.EQ(1.0, 1.0));
    Expect.isFalse(Helper.EQ(-1.0, 0.0));
    Expect.isFalse(Helper.EQ(-1.0, 1.0));
    Expect.isFalse(Helper.EQ(0.0, 1.0));

    Expect.isFalse(Helper.NE(-1.0, -1.0));
    Expect.isFalse(Helper.NE(0.0, 0.0));
    Expect.isFalse(Helper.NE(1.0, 1.0));
    Expect.isTrue(Helper.NE(-1.0, 0.0));
    Expect.isTrue(Helper.NE(-1.0, 1.0));
    Expect.isTrue(Helper.NE(0.0, 1.0));

    Expect.isFalse(Helper.LT(-1.0, -1.0));
    Expect.isFalse(Helper.LT(0.0, 0.0));
    Expect.isFalse(Helper.LT(1.0, 1.0));
    Expect.isTrue(Helper.LT(-1.0, 0.0));
    Expect.isTrue(Helper.LT(-1.0, 1.0));
    Expect.isTrue(Helper.LT(0.0, 1.0));
    Expect.isFalse(Helper.LT(0.0, -1.0));
    Expect.isFalse(Helper.LT(1.0, -1.0));
    Expect.isFalse(Helper.LT(1.0, 0.0));

    Expect.isTrue(Helper.LE(-1.0, -1.0));
    Expect.isTrue(Helper.LE(0.0, 0.0));
    Expect.isTrue(Helper.LE(1.0, 1.0));
    Expect.isTrue(Helper.LE(-1.0, 0.0));
    Expect.isTrue(Helper.LE(-1.0, 1.0));
    Expect.isTrue(Helper.LE(0.0, 1.0));
    Expect.isFalse(Helper.LE(0.0, -1.0));
    Expect.isFalse(Helper.LE(1.0, -1.0));
    Expect.isFalse(Helper.LE(1.0, 0.0));

    Expect.isFalse(Helper.GT(-1.0, -1.0));
    Expect.isFalse(Helper.GT(0.0, 0.0));
    Expect.isFalse(Helper.GT(1.0, 1.0));
    Expect.isFalse(Helper.GT(-1.0, 0.0));
    Expect.isFalse(Helper.GT(-1.0, 1.0));
    Expect.isFalse(Helper.GT(0.0, 1.0));
    Expect.isTrue(Helper.GT(0.0, -1.0));
    Expect.isTrue(Helper.GT(1.0, -1.0));
    Expect.isTrue(Helper.GT(1.0, 0.0));

    Expect.isTrue(Helper.GE(-1.0, -1.0));
    Expect.isTrue(Helper.GE(0.0, 0.0));
    Expect.isTrue(Helper.GE(1.0, 1.0));
    Expect.isFalse(Helper.GE(-1.0, 0.0));
    Expect.isFalse(Helper.GE(-1.0, 1.0));
    Expect.isFalse(Helper.GE(0.0, 1.0));
    Expect.isTrue(Helper.GE(0.0, -1.0));
    Expect.isTrue(Helper.GE(1.0, -1.0));
    Expect.isTrue(Helper.GE(1.0, 0.0));

    Expect.isTrue(Helper.EQ(null, null));
    Expect.isFalse(Helper.EQ(null, "Str"));
    Expect.isTrue(Helper.NE(null, 2));
    Expect.isFalse(Helper.NE(null, null));

    Expect.isTrue(Helper.STRICT_EQ(null, null));
    Expect.isFalse(Helper.STRICT_EQ(null, "Str"));
    Expect.isTrue(Helper.STRICT_NE(null, 2));
    Expect.isFalse(Helper.STRICT_NE(null, null));

    Expect.isFalse(Helper.GT(1, 1.2));
    Expect.isTrue(Helper.GT(3, 1.2));
    Expect.isTrue(Helper.GT(2.0, 1));
    Expect.isFalse(Helper.GT(3.1, 4));

    Expect.isFalse(Helper.GE(1, 1.2));
    Expect.isTrue(Helper.GE(3, 1.2));
    Expect.isTrue(Helper.GE(2.0, 1));
    Expect.isFalse(Helper.GE(3.1, 4));
    Expect.isTrue(Helper.GE(2.0, 2));
    Expect.isTrue(Helper.GE(2, 2.0));

    Expect.isTrue(Helper.LT(1, 1.2));
    Expect.isFalse(Helper.LT(3, 1.2));
    Expect.isFalse(Helper.LT(2.0, 1));
    Expect.isTrue(Helper.LT(3.1, 4));

    Expect.isTrue(Helper.LE(1, 1.2));
    Expect.isFalse(Helper.LE(3, 1.2));
    Expect.isFalse(Helper.LE(2.0, 1));
    Expect.isTrue(Helper.LE(3.1, 4));
    Expect.isTrue(Helper.LE(2.0, 2));
    Expect.isTrue(Helper.LE(2, 2.0));

    // Bignums.
    Expect.isTrue(Helper.LE(0xF00000000005, 0xF00000000006));
    Expect.isTrue(Helper.LE(0xF00000000005, 0xF00000000005));
    Expect.isFalse(Helper.LE(0xF00000000006, 0xF00000000005));
    Expect.isTrue(Helper.LE(12, 0xF00000000005));
    Expect.isTrue(Helper.LE(12.2, 0xF00000000005));

    Expect.isTrue(Helper.EQ(4294967295, 4.294967295e9));
    Expect.isTrue(Helper.EQ(4.294967295e9, 4294967295));
    Expect.isFalse(Helper.EQ(4.294967295e9, 42));
    Expect.isFalse(Helper.EQ(42, 4.294967295e9));
    Expect.isFalse(Helper.EQ(4294967295, 42));
    Expect.isFalse(Helper.EQ(42, 4294967295));

    // Fractions & mixed
    Expect.isTrue(Helper.EQ(1.0, 1));
    Expect.isTrue(Helper.EQ(1.0, 1));
    Expect.isTrue(Helper.EQ(1, 1.0));
    Expect.isTrue(Helper.EQ(1, 1.0));
    Expect.isTrue(Helper.EQ(1.1, 1.1));
    Expect.isTrue(Helper.EQ(1.1, 1.1));
    Expect.isTrue(Helper.EQ(1.1, 1.1));

    Expect.isFalse(Helper.GT(1, 1.2));
    Expect.isTrue(Helper.GT(1.2, 1));
    Expect.isTrue(Helper.GT(1.2, 1.1));
    Expect.isTrue(Helper.GT(1.2, 1.1));
    Expect.isTrue(Helper.GT(1.2, 1.1));

    Expect.isTrue(Helper.LT(1, 1.2));
    Expect.isFalse(Helper.LT(1.2, 1));
    Expect.isFalse(Helper.LT(1.2, 1.1));
    Expect.isFalse(Helper.LT(1.2, 1.1));
    Expect.isFalse(Helper.LT(1.2, 1.1));

    Expect.isFalse(Helper.GE(1.1, 1.2));
    Expect.isFalse(Helper.GE(1.1, 1.2));
    Expect.isTrue(Helper.GE(1.2, 1.2));
    Expect.isTrue(Helper.GE(1.2, 1.2));

    // With non-number classes.
    Expect.isFalse(Helper.EQ(1, "eeny"));
    Expect.isFalse(Helper.EQ("meeny", 1));
    Expect.isFalse(Helper.EQ(1.1, "miny"));
    Expect.isFalse(Helper.EQ("moe", 1.1));
    Expect.isFalse(Helper.EQ(1.1, "catch"));
    Expect.isFalse(Helper.EQ("the", 1.1));

    // With null.
    Expect.isFalse(Helper.EQ(1, null));
    Expect.isFalse(Helper.EQ(null, 1));
    Expect.isFalse(Helper.EQ(1.1, null));
    Expect.isFalse(Helper.EQ(null, 1.1));
    Expect.isFalse(Helper.EQ(1.1, null));
    Expect.isFalse(Helper.EQ(null, 1.1));

    // TODO(srdjan): Clarify behaviour of greater/less comparisons
    // between numbers and non-numbers.
  }
}

main() {
  ComparisonTest.testMain();
}
