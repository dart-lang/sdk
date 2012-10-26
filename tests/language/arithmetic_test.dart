// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

#library('arithmetic_test');
#import('dart:math');

class ArithmeticTest {

  static bool exceptionCaughtParseInt(String s) {
    try {
      parseInt(s);
      return false;
    } on FormatException catch (e) {
      return true;
    }
  }

  static bool exceptionCaughtParseDouble(String s) {
    try {
      parseDouble(s);
      return false;
    } on FormatException catch (e) {
      return true;
    }
  }

  static bool toIntThrowsFormatException(String str) {
    // No exception allowed for parse double.
    double d = parseDouble(str);
    try {
      var a = d.toInt();
      return false;
    } on FormatException catch (e) {
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
    Expect.equals(5.0, a ~/ b);
    Expect.equals(5.5, a / b);
    Expect.equals(2.0, a % b);
    Expect.equals(2.0, a.remainder(b));
    a = 22.0;
    b = 4;
    // Double & smi.
    Expect.equals(26.0, a + b);
    Expect.equals(18.0, a - b);
    Expect.equals(88.0, a * b);
    Expect.equals(5.0, a ~/ b);
    Expect.equals(5.5, a / b);
    Expect.equals(2.0, a % b);
    Expect.equals(2.0, a.remainder(b));
    a = 22.0;
    b = 4.0;
    // Double & double.
    Expect.equals(26.0, a + b);
    Expect.equals(18.0, a - b);
    Expect.equals(88.0, a * b);
    Expect.equals(5.0, a ~/ b);
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
    { double d = 1 + 1.0; }
    { double d = 1.0 + 1; }
    { double d = 1 * 1.0; }
    { double d = 0 * 1.0; }
    { double d = 1.0 * 0; }
    { double d = 1 / 1.0; }
    { double d = 1.0 / 0; }
    { double d = 1 - 1.0; }
    { double d = 1.0 - 1; }
    { double d = big * 1.0; }
    { double d = 1.0 * big; }

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
    final nan = 0.0/0.0;
    final infinity = 1.0/0.0;

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
    Expect.equals(0.0, (0.0).ceil());
    Expect.equals(false, (0.0).ceil().isNegative);
    Expect.equals(1.0, (0.1).ceil());
    Expect.equals(-0.0, (-0.0).ceil());
    Expect.equals(-0.0, (-0.3).ceil());
    // TODO(srdjan): enable the following tests once isNegative works.
    // Expect.equals(true, (-0.0).ceil().isNegative);
    // Expect.equals(true, (-0.3).ceil().isNegative);
    Expect.equals(3.0, (2.1).ceil());
    Expect.equals(-2.0, (-2.1).ceil());

    // -- floor --.
    // Smi.
    Expect.equals(0, (0).floor());
    Expect.equals(1, (1).floor());
    Expect.equals(-1, (-1).floor());
    // Big.
    Expect.equals(big, big.floor());
    Expect.equals(-big, (-big).floor());
    // Double.
    Expect.equals(0.0, (0.0).floor());
    Expect.equals(0.0, (0.1).floor());
    Expect.equals(false, (0.0).floor().isNegative);
    Expect.equals(false, (0.1).floor().isNegative);
    Expect.equals(-0.0, (-0.0).floor());
    // TODO(srdjan): enable the following tests once isNegative works.
    // Expect.equals(true, (-0.0).floor().isNegative);
    Expect.equals(-1.0, (-0.1).floor());
    Expect.equals(2.0, (2.1).floor());
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
    Expect.equals(0.0, (0.0).truncate());
    Expect.equals(0.0, (0.1).truncate());
    Expect.equals(false, (0.0).truncate().isNegative);
    Expect.equals(false, (0.1).truncate().isNegative);
    Expect.equals(-0.0, (-0.0).truncate());
    Expect.equals(-0.0, (-0.3).truncate());
    // TODO(srdjan): enable the following tests once isNegative works.
    // Expect.equals(true, (-0.0).truncate().isNegative);
    // Expect.equals(true, (-0.3).truncate().isNegative);
    Expect.equals(2.0, (2.1).truncate());
    Expect.equals(-2.0, (-2.1).truncate());

    double b1 = (1234567890123.0).truncate();
    double b2 = (1234567890124.0).truncate();
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
    Expect.equals(3.0, (2.6).round());
    Expect.equals(-3.0, (-2.6).round());
    Expect.equals(0.0, (0.0).round());
    Expect.equals(0.0, (0.1).round());
    Expect.equals(false, (0.0).round().isNegative);
    Expect.equals(false, (0.1).round().isNegative);
    Expect.equals(-0.0, (-0.0).round());
    Expect.equals(-0.0, (-0.3).round());
    Expect.equals(2.0, (2.1).round());
    Expect.equals(-2.0, (-2.1).round());
    Expect.equals(1.0, (0.5).round());
    // TODO(floitsch): enable or adapt test, once we reached conclusion on
    // b/4539188.
    // Expect.equals(-0.0, (-0.5).round());
    // TODO(srdjan): enable the following tests once isNegative works.
    // Expect.equals(true, (-0.0).round().isNegative);
    // Expect.equals(true, (-0.3).round().isNegative);
    // Expect.equals(true, (-0.5).round().isNegative);
    Expect.equals(2.0, (1.5).round());
    // TODO(floitsch): enable or adapt test, once we reached conclusion on
    // b/4539188.
    // Expect.equals(-1.0, (-1.5).round());
    Expect.equals(1.0, (0.99).round());

    // -- toInt --.
    // Smi.
    Expect.equals(0, (0).toInt());
    Expect.equals(1, (1).toInt());
    Expect.equals(-1, (-1).toInt());
    // Type checks.
    { int i = (0).toInt(); }
    { int i = (1).toInt(); }
    { int i = (-1).toInt(); }
    // Big.
    Expect.equals(big, big.toInt());
    Expect.equals(-big, (-big).toInt());
    { int i = big.toInt(); }
    { int i = (-big).toInt(); }
    // Double.
    Expect.equals(1234567890123, (1234567890123.0).toInt());
    Expect.equals(-1234567890123, (-1234567890123.0).toInt());
    { int i = (1234567890123.0).toInt(); }
    { int i = (-1234567890123.0).toInt(); }
    // 32bit Smi border cases.
    Expect.equals(-1073741824, (-1073741824.0).toInt());
    Expect.equals(-1073741825, (-1073741825.0).toInt());
    Expect.equals(1073741823, (1073741823.0).toInt());
    Expect.equals(1073741824, (1073741824.0).toInt());

    { int i = (-1073741824.0).toInt(); }
    { int i = (-1073741825.0).toInt(); }
    { int i = (1073741823.0).toInt(); }
    { int i = (1073741824.0).toInt(); }

    // -- toDouble --.
    // Smi.
    Expect.equals(0.0, (0).toDouble());
    Expect.equals(1.0, (1).toDouble());
    Expect.equals(-1.0, (-1).toDouble());
    // Type checks.
    { double d = (0).toDouble(); }
    { double d = (1).toDouble(); }
    { double d = (-1).toDouble(); }
    // Big.
    Expect.equals(big, big.toInt());
    Expect.equals(-big, (-big).toInt());
    { int i = big.toInt(); }
    { int i = (-big).toInt(); }

    // Math functions.
    Expect.equals(2.0, sqrt(4.0));
    Expect.approxEquals(1.0, sin(3.14159265 / 2.0));
    Expect.approxEquals(-1.0, cos(3.14159265));

    Expect.equals(12, parseInt("12"));
    Expect.equals(-12, parseInt("-12"));
    Expect.equals(12345678901234567890,
                  parseInt("12345678901234567890"));
    Expect.equals(-12345678901234567890,
                  parseInt("-12345678901234567890"));
    // Type checks.
    { int i = parseInt("12"); }
    { int i = parseInt("-12"); }
    { int i = parseInt("12345678901234567890"); }
    { int i = parseInt("-12345678901234567890"); }

    Expect.equals(1.2, parseDouble("1.2"));
    Expect.equals(-1.2, parseDouble("-1.2"));
    // Type checks.
    { double d = parseDouble("1.2"); }
    { double d = parseDouble("-1.2"); }
    { double d = parseDouble("0"); }

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

    Expect.equals(false, parseDouble("1.2").isNaN);
    Expect.equals(false, parseDouble("1.2").isInfinite);

    Expect.equals(true, parseDouble("NaN").isNaN);
    Expect.equals(true, parseDouble("Infinity").isInfinite);
    Expect.equals(true, parseDouble("-Infinity").isInfinite);

    Expect.equals(false, parseDouble("NaN").isNegative);
    Expect.equals(false, parseDouble("Infinity").isNegative);
    Expect.equals(true, parseDouble("-Infinity").isNegative);

    Expect.equals("NaN", parseDouble("NaN").toString());
    Expect.equals("Infinity", parseDouble("Infinity").toString());
    Expect.equals("-Infinity", parseDouble("-Infinity").toString());

    Expect.equals(false, toIntThrowsFormatException("1.2"));
    Expect.equals(true, toIntThrowsFormatException("Infinity"));
    Expect.equals(true, toIntThrowsFormatException("-Infinity"));
    Expect.equals(true, toIntThrowsFormatException("NaN"));

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

  static testMain() {
    for (int i = 0; i < 1500; i++) {
      runOne();
    }
  }
}

main() {
  ArithmeticTest.testMain();
}
