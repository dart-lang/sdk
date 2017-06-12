// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We temporarily test both the new math library and the old Math
// class. This can easily be simplified once we get rid of the Math
// class entirely.
library math_test;

import "package:expect/expect.dart";
import 'dart:math' as math;

class MathLibraryTest {
  static void testConstants() {
    // Source for mathematical constants is Wolfram Alpha.
    Expect.equals(
        2.7182818284590452353602874713526624977572470936999595749669, math.E);
    Expect.equals(2.3025850929940456840179914546843642076011014886287729760333,
        math.LN10);
    Expect.equals(
        0.6931471805599453094172321214581765680755001343602552541206, math.LN2);
    Expect.equals(1.4426950408889634073599246810018921374266459541529859341354,
        math.LOG2E);
    Expect.equals(0.4342944819032518276511289189166050822943970058036665661144,
        math.LOG10E);
    Expect.equals(
        3.1415926535897932384626433832795028841971693993751058209749, math.PI);
    Expect.equals(0.7071067811865475244008443621048490392848359376884740365883,
        math.SQRT1_2);
    Expect.equals(1.4142135623730950488016887242096980785696718753769480731766,
        math.SQRT2);
  }

  static checkClose(double a, double b, EPSILON) {
    Expect.equals(true, a - EPSILON <= b);
    Expect.equals(true, b <= a + EPSILON);
  }

  static void testSin() {
    // Given the imprecision of PI we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, math.sin(0.0), EPSILON);
    checkClose(0.0, math.sin(math.PI), EPSILON);
    checkClose(0.0, math.sin(2.0 * math.PI), EPSILON);
    checkClose(1.0, math.sin(math.PI / 2.0), EPSILON);
    checkClose(-1.0, math.sin(math.PI * (3.0 / 2.0)), EPSILON);
  }

  static void testCos() {
    // Given the imprecision of PI we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(1.0, math.cos(0.0), EPSILON);
    checkClose(-1.0, math.cos(math.PI), EPSILON);
    checkClose(1.0, math.cos(2.0 * math.PI), EPSILON);
    checkClose(0.0, math.cos(math.PI / 2.0), EPSILON);
    checkClose(0.0, math.cos(math.PI * (3.0 / 2.0)), EPSILON);
  }

  static void testTan() {
    // Given the imprecision of PI we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, math.tan(0.0), EPSILON);
    checkClose(0.0, math.tan(math.PI), EPSILON);
    checkClose(0.0, math.tan(2.0 * math.PI), EPSILON);
    checkClose(1.0, math.tan(math.PI / 4.0), EPSILON);
  }

  static void testAsin() {
    // Given the imprecision of PI we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, math.asin(0.0), EPSILON);
    checkClose(math.PI / 2.0, math.asin(1.0), EPSILON);
    checkClose(-math.PI / 2.0, math.asin(-1.0), EPSILON);
  }

  static void testAcos() {
    // Given the imprecision of PI we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, math.acos(1.0), EPSILON);
    checkClose(math.PI, math.acos(-1.0), EPSILON);
    checkClose(math.PI / 2.0, math.acos(0.0), EPSILON);
  }

  static void testAtan() {
    // Given the imprecision of PI we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, math.atan(0.0), EPSILON);
    checkClose(math.PI / 4.0, math.atan(1.0), EPSILON);
    checkClose(-math.PI / 4.0, math.atan(-1.0), EPSILON);
  }

  static void testAtan2() {
    // Given the imprecision of PI we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, math.atan2(0.0, 5.0), EPSILON);
    checkClose(math.PI / 4.0, math.atan2(2.0, 2.0), EPSILON);
    checkClose(3 * math.PI / 4.0, math.atan2(0.5, -0.5), EPSILON);
    checkClose(-3 * math.PI / 4.0, math.atan2(-2.5, -2.5), EPSILON);
  }

  static checkVeryClose(double a, double b) {
    // We find a ulp (unit in the last place) by shifting the original number
    // to the right. This only works if we are not too close to infinity or if
    // we work with denormals.
    // We special case or 0.0, but not for infinity.
    if (a == 0.0) {
      final minimalDouble = 4.9406564584124654e-324;
      Expect.equals(true, b.abs() <= minimalDouble);
      return;
    }
    if (b == 0.0) {
      // No need to look if they are close. Otherwise the check for 'a' above
      // whould have triggered.
      Expect.equals(a, b);
    }
    final double shiftRightBy52 = 2.220446049250313080847263336181640625e-16;
    final double shiftedA = (a * shiftRightBy52).abs();
    // Compared to 'a', 'shiftedA' is now ~1-2 ulp.

    final double limitLow = a - shiftedA;
    final double limitHigh = a + shiftedA;
    Expect.equals(false, a == limitLow);
    Expect.equals(false, a == limitHigh);
    Expect.equals(true, limitLow <= b);
    Expect.equals(true, b <= limitHigh);
  }

  static void testSqrt() {
    checkVeryClose(2.0, math.sqrt(4.0));
    checkVeryClose(math.SQRT2, math.sqrt(2.0));
    checkVeryClose(math.SQRT1_2, math.sqrt(0.5));
    checkVeryClose(1e50, math.sqrt(1e100));
    checkVeryClose(1.1111111061110855443054405046358901279277111935183977e56,
        math.sqrt(12345678901234e99));
  }

  static void testExp() {
    checkVeryClose(math.E, math.exp(1.0));
    final EPSILON = 1e-15;
    checkClose(10.0, math.exp(math.LN10), EPSILON);
    checkClose(2.0, math.exp(math.LN2), EPSILON);
  }

  static void testLog() {
    // Even though E is imprecise, it is good enough to get really close to 1.
    // We still provide an epsilon.
    checkClose(1.0, math.log(math.E), 1e-16);
    checkVeryClose(math.LN10, math.log(10.0));
    checkVeryClose(math.LN2, math.log(2.0));
  }

  static void testPow() {
    checkVeryClose(16.0, math.pow(4.0, 2.0));
    checkVeryClose(math.SQRT2, math.pow(2.0, 0.5));
    checkVeryClose(math.SQRT1_2, math.pow(0.5, 0.5));
  }

  static bool parseIntThrowsFormatException(str) {
    try {
      int.parse(str);
      return false;
    } on FormatException catch (e) {
      return true;
    }
  }

  static void testParseInt() {
    Expect.equals(499, int.parse("499"));
    Expect.equals(499, int.parse("+499"));
    Expect.equals(-499, int.parse("-499"));
    Expect.equals(499, int.parse("   499   "));
    Expect.equals(499, int.parse("   +499   "));
    Expect.equals(-499, int.parse("   -499   "));
    Expect.equals(0, int.parse("0"));
    Expect.equals(0, int.parse("+0"));
    Expect.equals(0, int.parse("-0"));
    Expect.equals(0, int.parse("   0   "));
    Expect.equals(0, int.parse("   +0   "));
    Expect.equals(0, int.parse("   -0   "));
    Expect.equals(0x1234567890, int.parse("0x1234567890"));
    Expect.equals(-0x1234567890, int.parse("-0x1234567890"));
    Expect.equals(0x1234567890, int.parse("   0x1234567890   "));
    Expect.equals(-0x1234567890, int.parse("   -0x1234567890   "));
    Expect.equals(256, int.parse("0x100"));
    Expect.equals(-256, int.parse("-0x100"));
    Expect.equals(256, int.parse("   0x100   "));
    Expect.equals(-256, int.parse("   -0x100   "));
    Expect.equals(0xabcdef, int.parse("0xabcdef"));
    Expect.equals(0xABCDEF, int.parse("0xABCDEF"));
    Expect.equals(0xabcdef, int.parse("0xabCDEf"));
    Expect.equals(-0xabcdef, int.parse("-0xabcdef"));
    Expect.equals(-0xABCDEF, int.parse("-0xABCDEF"));
    Expect.equals(0xabcdef, int.parse("   0xabcdef   "));
    Expect.equals(0xABCDEF, int.parse("   0xABCDEF   "));
    Expect.equals(-0xabcdef, int.parse("   -0xabcdef   "));
    Expect.equals(-0xABCDEF, int.parse("   -0xABCDEF   "));
    Expect.equals(0xabcdef, int.parse("0x00000abcdef"));
    Expect.equals(0xABCDEF, int.parse("0x00000ABCDEF"));
    Expect.equals(-0xabcdef, int.parse("-0x00000abcdef"));
    Expect.equals(-0xABCDEF, int.parse("-0x00000ABCDEF"));
    Expect.equals(0xabcdef, int.parse("   0x00000abcdef   "));
    Expect.equals(0xABCDEF, int.parse("   0x00000ABCDEF   "));
    Expect.equals(-0xabcdef, int.parse("   -0x00000abcdef   "));
    Expect.equals(-0xABCDEF, int.parse("   -0x00000ABCDEF   "));
    Expect.equals(10, int.parse("010"));
    Expect.equals(-10, int.parse("-010"));
    Expect.equals(10, int.parse("   010   "));
    Expect.equals(-10, int.parse("   -010   "));
    Expect.equals(9, int.parse("09"));
    Expect.equals(9, int.parse(" 09 "));
    Expect.equals(-9, int.parse("-09"));
    Expect.equals(0x1234567890, int.parse("+0x1234567890"));
    Expect.equals(0x1234567890, int.parse("   +0x1234567890   "));
    Expect.equals(0x100, int.parse("+0x100"));
    Expect.equals(0x100, int.parse("   +0x100   "));

    Expect.equals(true, parseIntThrowsFormatException("1b"));
    Expect.equals(true, parseIntThrowsFormatException(" 1b "));
    Expect.equals(true, parseIntThrowsFormatException(" 1 b "));
    Expect.equals(true, parseIntThrowsFormatException("1e2"));
    Expect.equals(true, parseIntThrowsFormatException(" 1e2 "));
    Expect.equals(true, parseIntThrowsFormatException("00x12"));
    Expect.equals(true, parseIntThrowsFormatException(" 00x12 "));
    Expect.equals(true, parseIntThrowsFormatException("-1b"));
    Expect.equals(true, parseIntThrowsFormatException(" -1b "));
    Expect.equals(true, parseIntThrowsFormatException(" -1 b "));
    Expect.equals(true, parseIntThrowsFormatException("-1e2"));
    Expect.equals(true, parseIntThrowsFormatException(" -1e2 "));
    Expect.equals(true, parseIntThrowsFormatException("-00x12"));
    Expect.equals(true, parseIntThrowsFormatException(" -00x12 "));
    Expect.equals(true, parseIntThrowsFormatException("  -00x12 "));
    Expect.equals(true, parseIntThrowsFormatException("0x0x12"));
    Expect.equals(true, parseIntThrowsFormatException("0.1"));
    Expect.equals(true, parseIntThrowsFormatException("0x3.1"));
    Expect.equals(true, parseIntThrowsFormatException("5."));
    Expect.equals(true, parseIntThrowsFormatException("+-5"));
    Expect.equals(true, parseIntThrowsFormatException("-+5"));
    Expect.equals(true, parseIntThrowsFormatException("--5"));
    Expect.equals(true, parseIntThrowsFormatException("++5"));
    Expect.equals(true, parseIntThrowsFormatException("+ 5"));
    Expect.equals(true, parseIntThrowsFormatException("- 5"));
    Expect.equals(true, parseIntThrowsFormatException(""));
    Expect.equals(true, parseIntThrowsFormatException("  "));
  }

  static testMain() {
    testConstants();
    testSin();
    testCos();
    testTan();
    testAsin();
    testAcos();
    testAtan();
    testAtan2();
    testSqrt();
    testLog();
    testExp();
    testPow();
    testParseInt();
  }
}

main() {
  MathLibraryTest.testMain();
}
