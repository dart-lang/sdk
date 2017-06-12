// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

library arithmetic_test;

import "package:expect/expect.dart";
import 'dart:math';

class ArithmeticTest {
  static bool exceptionCaughtParseInt(String s) {
    try {
      int.parse(s);
      return false;
    } on FormatException catch (e) {
      return true;
    }
  }

  static bool exceptionCaughtParseDouble(String s) {
    try {
      double.parse(s);
      return false;
    } on FormatException catch (e) {
      return true;
    }
  }

  static bool toIntThrowsUnsupportedError(String str) {
    // No exception allowed for parse double.
    double d = double.parse(str);
    try {
      var a = d.toInt();
      return false;
    } on UnsupportedError catch (e) {
      return true;
    }
  }

  static runOne() {
    var a = 22;
    var b = 4;
    // Smi & smi.
    Expect.equals(26, a + b);
    Expect.equals(18, a - b);
    Expect.equals(88, a * b);
    Expect.equals(5, a ~/ b);
    Expect.equals(5.5, a / b);
    Expect.equals(2.0, 10 / 5);
    Expect.equals(2, a % b);
    Expect.equals(2, a.remainder(b));
    // Smi corner cases.
    for (int i = 0; i < 80; i++) {
      a = -(1 << i);
      b = -1;
      Expect.equals(1 << i, a ~/ b);
    }
    a = 22;
    b = 4.0;
    // Smi & double.
    Expect.equals(26.0, a + b);
    Expect.equals(18.0, a - b);
    Expect.equals(88.0, a * b);
    Expect.equals(5, a ~/ b);
    Expect.equals(5.5, a / b);
    Expect.equals(2.0, a % b);
    Expect.equals(2.0, a.remainder(b));
    a = 22.0;
    b = 4;
    // Double & smi.
    Expect.equals(26.0, a + b);
    Expect.equals(18.0, a - b);
    Expect.equals(88.0, a * b);
    Expect.equals(5, a ~/ b);
    Expect.equals(5.5, a / b);
    Expect.equals(2.0, a % b);
    Expect.equals(2.0, a.remainder(b));
    a = 22.0;
    b = 4.0;
    // Double & double.
    Expect.equals(26.0, a + b);
    Expect.equals(18.0, a - b);
    Expect.equals(88.0, a * b);
    Expect.equals(5, a ~/ b);
    Expect.equals(5.5, a / b);
    Expect.equals(2.0, a % b);
    Expect.equals(2.0, a.remainder(b));

    // Special int operations.
    Expect.equals(2, (2).floor());
    Expect.equals(2, (2).ceil());
    Expect.equals(2, (2).round());
    Expect.equals(2, (2).truncate());

    Expect.equals(-2, (-2).floor());
    Expect.equals(-2, (-2).ceil());
    Expect.equals(-2, (-2).round());
    Expect.equals(-2, (-2).truncate());

    // Note that this number fits into 53 bits of a double.
    int big = 123456789012345;

    Expect.equals(big, big.floor());
    Expect.equals(big, big.ceil());
    Expect.equals(big, big.round());
    Expect.equals(big, big.truncate());
    big = -big;
    Expect.equals(big, big.floor());
    Expect.equals(big, big.ceil());
    Expect.equals(big, big.round());
    Expect.equals(big, big.truncate());

    // Test if double is contagious. The assignment will check the type.
    {
      double d = 1 + 1.0;
    }
    {
      double d = 1.0 + 1;
    }
    {
      double d = 1 * 1.0;
    }
    {
      double d = 0 * 1.0;
    }
    {
      double d = 1.0 * 0;
    }
    {
      double d = 1 / 1.0;
    }
    {
      double d = 1.0 / 0;
    }
    {
      double d = 1 - 1.0;
    }
    {
      double d = 1.0 - 1;
    }
    {
      double d = big * 1.0;
    }
    {
      double d = 1.0 * big;
    }

    // Reset big to positive value.
    big = 123456789012345;
    // -- isNegative --.
    // Smi.
    Expect.equals(false, (0).isNegative);
    Expect.equals(false, (1).isNegative);
    Expect.equals(true, (-1).isNegative);
    // Big.
    Expect.equals(false, big.isNegative);
    Expect.equals(true, (-big).isNegative);
    // Double.
    // TODO(srdjan): enable the following test once isNegative works.
    // Expect.equals(true, (-0.0).isNegative);
    Expect.equals(false, (0.0).isNegative);
    Expect.equals(false, (2.0).isNegative);
    Expect.equals(true, (-2.0).isNegative);

    double negateDouble(double x) {
      return -x;
    }

    Expect.isTrue(negateDouble(0.0).isNegative);
    Expect.isFalse(negateDouble(-0.0).isNegative);
    Expect.isTrue(negateDouble(3.5e3).isNegative);
    Expect.isFalse(negateDouble(-3.5e3).isNegative);

    // Constants.
    final nan = 0.0 / 0.0;
    final infinity = 1.0 / 0.0;

    // -- isInfinite --.
    // Smi.
    Expect.equals(false, (0).isInfinite);
    Expect.equals(false, (1).isInfinite);
    Expect.equals(false, (-1).isInfinite);
    // Big.
    Expect.equals(false, big.isInfinite);
    Expect.equals(false, (-big).isInfinite);
    // Double.
    Expect.equals(false, (0.0).isInfinite);
    Expect.equals(true, infinity.isInfinite);
    Expect.equals(true, (-infinity).isInfinite);
    Expect.equals(false, (12.0).isInfinite);
    Expect.equals(false, (-12.0).isInfinite);
    Expect.equals(false, nan.isInfinite);

    // -- isNaN --.
    // Smi.
    Expect.equals(false, (0).isNaN);
    Expect.equals(false, (1).isNaN);
    Expect.equals(false, (-1).isNaN);
    // Big.
    Expect.equals(false, big.isNaN);
    Expect.equals(false, (-big).isNaN);
    // Double.
    Expect.equals(true, nan.isNaN);
    Expect.equals(false, (12.0).isNaN);
    Expect.equals(false, infinity.isNaN);

    // -- abs --.
    // Smi.
    Expect.equals(0, (0).abs());
    Expect.equals(2, (2).abs());
    Expect.equals(2, (-2).abs());
    // Big.
    Expect.equals(big, big.abs());
    Expect.equals(big, (-big).abs());
    // Double.
    Expect.equals(false, (0.0).abs().isNegative);
    Expect.equals(false, (-0.0).abs().isNegative);
    Expect.equals(2.0, (2.0).abs());
    Expect.equals(2.0, (-2.0).abs());

    // -- ceil --.
    // Smi.
    Expect.equals(0, (0).ceil());
    Expect.equals(1, (1).ceil());
    Expect.equals(-1, (-1).ceil());
    // Big.
    Expect.equals(big, big.ceil());
    Expect.equals(-big, (-big).ceil());
    // Double.
    Expect.equals(0, (0.0).ceil());
    Expect.equals(false, (0.0).ceil().isNegative);
    Expect.equals(1, (0.1).ceil());
    Expect.equals(1, double.MIN_POSITIVE.ceil());
    Expect.equals(1, (0.49999999999999994).ceil());
    Expect.equals(0, (-0.0).ceil());
    Expect.equals(0, (-0.3).ceil());
    Expect.isTrue((-0.0).ceil() is int);
    Expect.isTrue((-0.3).ceil() is int);
    Expect.equals(0, (-0.49999999999999994).ceil());
    Expect.equals(3, (2.1).ceil());
    Expect.equals(-2, (-2.1).ceil());

    // -- floor --.
    // Smi.
    Expect.equals(0, (0).floor());
    Expect.equals(1, (1).floor());
    Expect.equals(-1, (-1).floor());
    // Big.
    Expect.equals(big, big.floor());
    Expect.equals(-big, (-big).floor());
    // Double.
    Expect.equals(0, (0.0).floor());
    Expect.equals(0, (0.1).floor());
    Expect.equals(0, (0.49999999999999994).floor());
    Expect.equals(0, double.MIN_POSITIVE.floor());
    Expect.isTrue((0.0).floor() is int);
    Expect.isTrue((0.1).floor() is int);
    Expect.equals(0, (-0.0).floor());
    Expect.isTrue((-0.0).floor() is int);
    Expect.equals(-1, (-0.1).floor());
    Expect.equals(2, (2.1).floor());
    Expect.equals(-3, (-2.1).floor());
    Expect.equals(-1.0, (-0.49999999999999994).floor());
    Expect.equals(-3.0, (-2.1).floor());

    // -- truncate --.
    // Smi.
    Expect.equals(0, (0).truncate());
    Expect.equals(1, (1).truncate());
    Expect.equals(-1, (-1).truncate());
    // Big.
    Expect.equals(big, big.truncate());
    Expect.equals(-big, (-big).truncate());
    // Double.
    Expect.equals(0, (0.0).truncate());
    Expect.equals(0, (0.1).truncate());
    Expect.isTrue((0.0).truncate() is int);
    Expect.isTrue((0.1).truncate() is int);
    Expect.equals(0, (-0.0).truncate());
    Expect.equals(0, (-0.3).truncate());
    Expect.isTrue((-0.0).truncate() is int);
    Expect.isTrue((-0.3).truncate() is int);
    Expect.equals(2, (2.1).truncate());
    Expect.equals(-2, (-2.1).truncate());

    int b1 = (1234567890123.0).truncate();
    int b2 = (1234567890124.0).truncate();
    Expect.equals(b2, b1 + 1.0);

    // -- round --.
    // Smi.
    Expect.equals(0, (0).round());
    Expect.equals(1, (1).round());
    Expect.equals(-1, (-1).round());
    // Big.
    Expect.equals(big, big.round());
    Expect.equals(-big, (-big).round());
    // Double.
    Expect.equals(3, (2.6).round());
    Expect.equals(-3, (-2.6).round());
    Expect.equals(0, (0.0).round());
    Expect.equals(0, (0.1).round());
    Expect.equals(3, (2.5).round());
    Expect.equals(-3, (-2.5).round());
    Expect.isFalse((0.0).round().isNegative);
    Expect.isFalse((0.1).round().isNegative);
    Expect.equals(0, (-0.0).round());
    Expect.equals(0, (-0.3).round());
    Expect.equals(2, (2.1).round());
    Expect.equals(-2, (-2.1).round());
    Expect.equals(1, (0.5).round());
    Expect.equals(-1, (-0.5).round());
    Expect.isTrue((-0.0).round() is int);
    Expect.isTrue((-0.3).round() is int);
    Expect.isTrue((-0.5).round() is int);
    Expect.equals(2, (1.5).round());
    Expect.equals(-2, (-1.5).round());
    Expect.equals(1, (0.99).round());

    // -- toInt --.
    // Smi.
    Expect.equals(0, (0).toInt());
    Expect.equals(1, (1).toInt());
    Expect.equals(-1, (-1).toInt());
    // Type checks.
    {
      int i = (0).toInt();
    }
    {
      int i = (1).toInt();
    }
    {
      int i = (-1).toInt();
    }
    // Big.
    Expect.equals(big, big.toInt());
    Expect.equals(-big, (-big).toInt());
    {
      int i = big.toInt();
    }
    {
      int i = (-big).toInt();
    }
    // Double.
    Expect.equals(1234567890123, (1234567890123.0).toInt());
    Expect.equals(-1234567890123, (-1234567890123.0).toInt());
    {
      int i = (1234567890123.0).toInt();
    }
    {
      int i = (-1234567890123.0).toInt();
    }
    // 32bit Smi border cases.
    Expect.equals(-1073741824, (-1073741824.0).toInt());
    Expect.equals(-1073741825, (-1073741825.0).toInt());
    Expect.equals(1073741823, (1073741823.0).toInt());
    Expect.equals(1073741824, (1073741824.0).toInt());

    {
      int i = (-1073741824.0).toInt();
    }
    {
      int i = (-1073741825.0).toInt();
    }
    {
      int i = (1073741823.0).toInt();
    }
    {
      int i = (1073741824.0).toInt();
    }

    // -- toDouble --.
    // Smi.
    Expect.equals(0.0, (0).toDouble());
    Expect.equals(1.0, (1).toDouble());
    Expect.equals(-1.0, (-1).toDouble());
    // Type checks.
    {
      double d = (0).toDouble();
    }
    {
      double d = (1).toDouble();
    }
    {
      double d = (-1).toDouble();
    }
    // Big.
    Expect.equals(big, big.toInt());
    Expect.equals(-big, (-big).toInt());
    {
      int i = big.toInt();
    }
    {
      int i = (-big).toInt();
    }

    // Math functions.
    Expect.equals(2.0, sqrt(4.0));
    Expect.approxEquals(1.0, sin(3.14159265 / 2.0));
    Expect.approxEquals(-1.0, cos(3.14159265));

    Expect.equals(12, int.parse("12"));
    Expect.equals(-12, int.parse("-12"));
    Expect.equals(12345678901234567890, int.parse("12345678901234567890"));
    Expect.equals(-12345678901234567890, int.parse("-12345678901234567890"));
    // Type checks.
    {
      int i = int.parse("12");
    }
    {
      int i = int.parse("-12");
    }
    {
      int i = int.parse("12345678901234567890");
    }
    {
      int i = int.parse("-12345678901234567890");
    }

    Expect.equals(1.2, double.parse("1.2"));
    Expect.equals(-1.2, double.parse("-1.2"));
    // Type checks.
    {
      double d = double.parse("1.2");
    }
    {
      double d = double.parse("-1.2");
    }
    {
      double d = double.parse("0");
    }

    // Random
    {
      Random rand = new Random();
      double d = rand.nextDouble();
    }

    Expect.equals(false, exceptionCaughtParseInt("22"));
    Expect.equals(true, exceptionCaughtParseInt("alpha"));
    Expect.equals(true, exceptionCaughtParseInt("-alpha"));
    Expect.equals(false, exceptionCaughtParseDouble("22.2"));
    Expect.equals(true, exceptionCaughtParseDouble("alpha"));
    Expect.equals(true, exceptionCaughtParseDouble("-alpha"));

    Expect.equals(false, double.parse("1.2").isNaN);
    Expect.equals(false, double.parse("1.2").isInfinite);

    Expect.equals(true, double.parse("NaN").isNaN);
    Expect.equals(true, double.parse("Infinity").isInfinite);
    Expect.equals(true, double.parse("-Infinity").isInfinite);

    Expect.equals(false, double.parse("NaN").isNegative);
    Expect.equals(false, double.parse("Infinity").isNegative);
    Expect.equals(true, double.parse("-Infinity").isNegative);

    Expect.equals("NaN", double.parse("NaN").toString());
    Expect.equals("Infinity", double.parse("Infinity").toString());
    Expect.equals("-Infinity", double.parse("-Infinity").toString());

    Expect.equals(false, toIntThrowsUnsupportedError("1.2"));
    Expect.equals(true, toIntThrowsUnsupportedError("Infinity"));
    Expect.equals(true, toIntThrowsUnsupportedError("-Infinity"));
    Expect.equals(true, toIntThrowsUnsupportedError("NaN"));

    // Min/max
    Expect.equals(1, min(1, 12));
    Expect.equals(12, max(1, 12));
    Expect.equals(1.0, min(1.0, 12.0));
    Expect.equals(12.0, max(1.0, 12.0));
    Expect.equals(false, 1.0 < min(1.0, 12.0));
    Expect.equals(true, 1.0 < max(1.0, 12.0));

    // Hashcode
    Expect.equals(false, (3.4).hashCode == (1.2).hashCode);
    Expect.equals(true, (1.2).hashCode == (1.2).hashCode);
    Expect.equals(false, (3).hashCode == (1).hashCode);
    Expect.equals(true, (10).hashCode == (10).hashCode);
  }

  static int div(a, b) => a ~/ b;

  static void testSmiDivDeopt() {
    var a = -0x40000000;
    var b = -1;
    for (var i = 0; i < 10; i++) Expect.equals(0x40000000, div(a, b));
  }

  static int divMod(a, b) => a ~/ b + a % b;

  static void testSmiDivModDeopt() {
    var a = -0x40000000;
    var b = -1;
    for (var i = 0; i < 10; i++) Expect.equals(0x40000000, divMod(a, b));
  }

  static double sinCosSub(double a) => sin(a) - cos(a);

  static double sinCosAddCos(double a) => sin(a) * cos(a) + cos(a);

  static void testSinCos() {
    var e = sin(1.234) - cos(1.234);
    var f = sin(1.234) * cos(1.234) + cos(1.234);

    for (var i = 0; i < 20; i++) {
      Expect.approxEquals(e, sinCosSub(1.234));
      Expect.approxEquals(f, sinCosAddCos(1.234));
    }
    Expect.approxEquals(1.0, sinCosSub(3.14159265));
    Expect.approxEquals(1.0, sinCosSub(3.14159265 / 2.0));
  }

  // Test fix for issue 16592.
  static void testSinCosNoUse() {
    for (var i = 0; i < 20; i++) {
      sin(i);
      cos(i);
    }
  }

  static mySqrt(var x) => sqrt(x);

  static testSqrtDeopt() {
    for (var i = 0; i < 10; i++) mySqrt(4.0);
    Expect.equals(2.0, mySqrt(4.0));
    Expect.throws(() => mySqrt("abc"));
  }

  static self_equality(x) {
    return x == x;
  }

  static testDoubleEquality() {
    Expect.isFalse(self_equality(double.NAN));
    for (int i = 0; i < 20; i++) {
      self_equality(3.0);
    }
    Expect.isFalse(self_equality(double.NAN));
  }

  static testMain() {
    for (int i = 0; i < 20; i++) {
      runOne();
      testSmiDivDeopt();
      testSmiDivModDeopt();
      testSqrtDeopt();
      testDoubleEquality();
      testSinCos();
      testSinCosNoUse();
    }
  }
}

main() {
  ArithmeticTest.testMain();
}
