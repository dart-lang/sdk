// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library math_test;

import "package:expect/expect.dart";
import 'dart:math';

class MathTest {
  static void testConstants() {
    // Source for mathematical constants is Wolfram Alpha.
    Expect.equals(
        2.7182818284590452353602874713526624977572470936999595749669, e);
    Expect.equals(
        2.3025850929940456840179914546843642076011014886287729760333, ln10);
    Expect.equals(
        0.6931471805599453094172321214581765680755001343602552541206, ln2);
    Expect.equals(
        1.4426950408889634073599246810018921374266459541529859341354, log2e);
    Expect.equals(
        0.4342944819032518276511289189166050822943970058036665661144, log10e);
    Expect.equals(
        3.1415926535897932384626433832795028841971693993751058209749, pi);
    Expect.equals(
        0.7071067811865475244008443621048490392848359376884740365883, sqrt1_2);
    Expect.equals(
        1.4142135623730950488016887242096980785696718753769480731766, sqrt2);
  }

  static checkClose(double a, double b, EPSILON) {
    Expect.equals(true, a - EPSILON <= b);
    Expect.equals(true, b <= a + EPSILON);
  }

  static void testSin() {
    // Given the imprecision of pi we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, sin(0.0), EPSILON);
    checkClose(0.0, sin(pi), EPSILON);
    checkClose(0.0, sin(2.0 * pi), EPSILON);
    checkClose(1.0, sin(pi / 2.0), EPSILON);
    checkClose(-1.0, sin(pi * (3.0 / 2.0)), EPSILON);
  }

  static void testCos() {
    // Given the imprecision of pi we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(1.0, cos(0.0), EPSILON);
    checkClose(-1.0, cos(pi), EPSILON);
    checkClose(1.0, cos(2.0 * pi), EPSILON);
    checkClose(0.0, cos(pi / 2.0), EPSILON);
    checkClose(0.0, cos(pi * (3.0 / 2.0)), EPSILON);
  }

  static void testTan() {
    // Given the imprecision of pi we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, tan(0.0), EPSILON);
    checkClose(0.0, tan(pi), EPSILON);
    checkClose(0.0, tan(2.0 * pi), EPSILON);
    checkClose(1.0, tan(pi / 4.0), EPSILON);
  }

  static void testAsin() {
    // Given the imprecision of pi we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, asin(0.0), EPSILON);
    checkClose(pi / 2.0, asin(1.0), EPSILON);
    checkClose(-pi / 2.0, asin(-1.0), EPSILON);
  }

  static void testAcos() {
    // Given the imprecision of pi we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, acos(1.0), EPSILON);
    checkClose(pi, acos(-1.0), EPSILON);
    checkClose(pi / 2.0, acos(0.0), EPSILON);
  }

  static void testAtan() {
    // Given the imprecision of pi we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, atan(0.0), EPSILON);
    checkClose(pi / 4.0, atan(1.0), EPSILON);
    checkClose(-pi / 4.0, atan(-1.0), EPSILON);
  }

  static void testAtan2() {
    // Given the imprecision of pi we can't expect better results than this.
    final double EPSILON = 1e-15;
    checkClose(0.0, atan2(0.0, 5.0), EPSILON);
    checkClose(pi / 4.0, atan2(2.0, 2.0), EPSILON);
    checkClose(3 * pi / 4.0, atan2(0.5, -0.5), EPSILON);
    checkClose(-3 * pi / 4.0, atan2(-2.5, -2.5), EPSILON);
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
    checkVeryClose(2.0, sqrt(4.0));
    checkVeryClose(sqrt2, sqrt(2.0));
    checkVeryClose(sqrt1_2, sqrt(0.5));
    checkVeryClose(1e50, sqrt(1e100));
    checkVeryClose(1.1111111061110855443054405046358901279277111935183977e56,
        sqrt(12345678901234e99));
  }

  static void testExp() {
    checkVeryClose(e, exp(1.0));
    final EPSILON = 1e-15;
    checkClose(10.0, exp(ln10), EPSILON);
    checkClose(2.0, exp(ln2), EPSILON);
  }

  static void testLog() {
    // Even though E is imprecise, it is good enough to get really close to 1.
    // We still provide an epsilon.
    checkClose(1.0, log(e), 1e-16);
    checkVeryClose(ln10, log(10.0));
    checkVeryClose(ln2, log(2.0));
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
    testParseInt();
  }
}

main() {
  MathTest.testMain();
}
