// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library math_test;
import "package:expect/expect.dart";
import 'dart:math';
import 'package:math/math.dart';

// See gcd_test.dart first.  This file contains only the tests that need Bigint
// or would fail in dart2js compatibility mode.

class BigintTest {
  // 8 random primes less within [2^60, 2^64]
  final int p1 = 6714601027348841563;
  final int p2 = 13464639003769154407;
  final int p3 = 9519493673324441563;
  final int p4 = 7064784879742017229;
  final int p5 = 18364232533526122157;
  final int p6 = 2099437422495963203;
  final int p7 = 10166792634765954647;
  final int p8 = 2745073355742392083;

  void testGcdWithBigints() {
    Expect.equals(pow(2, 63)*3, gcd(pow(2, 64)*3*5, pow(2, 63)*3*7));
    // 595056260442243647 is the first prime after 2**64 / 31.
    Expect.equals(595056260442243647,
      gcd(31*595056260442243647, 37*595056260442243647));
    Expect.equals(p2, gcd(p1*p2, p2*p3));
    Expect.equals(1, gcd(p1*p2, p3*p4));

    // Negatives
    Expect.equals(pow(2, 63)*3, gcd(-pow(2, 64)*3*5, pow(2, 63)*3*7));
    Expect.equals(pow(2, 63)*3, gcd(pow(2, 64)*3*5, -pow(2, 63)*3*7));
    Expect.equals(pow(2, 63)*3, gcd(-pow(2, 64)*3*5, -pow(2, 63)*3*7));
    Expect.equals(1, gcd(-p1, p2));
    Expect.equals(1, gcd(p1, -p2));
    Expect.equals(1, gcd(-p1, -p2));
  }

  void testGcdextWithBigints() {
    Expect.listEquals([pow(2, 63)*3, -2, 3],
      gcdext(pow(2, 64)*3*5, pow(2, 63)*3*7));
    // 595056260442243647 is the first prime after 2**64 / 31.
    Expect.listEquals([595056260442243647, 6, -5],
      gcdext(31*595056260442243647, 37*595056260442243647));
    Expect.listEquals([1, 970881267037344823, -970881267037344822],
      gcdext(73786976294838206473, 73786976294838206549));
    Expect.listEquals([1, 796993873408264695, -397448151389712212],
      gcdext(p1, p2));
    Expect.listEquals([1, -397448151389712212, 796993873408264695],
      gcdext(p2, p1));

    // Negatives
    Expect.listEquals([1, -796993873408264695, -397448151389712212],
      gcdext(-p1, p2));
    Expect.listEquals([1, 796993873408264695, 397448151389712212],
      gcdext(p1, -p2));
    Expect.listEquals([1, -796993873408264695, 397448151389712212],
      gcdext(-p1, -p2));
  }

  void testInvertWithBigints() {
    // 9223372036854775837 is the first prime after 2^63.
    Expect.equals(2093705452366034115, invert(1000, 9223372036854775837));
    Expect.equals(970547769322117497, invert(1000000, 9223372036854775837));

    Expect.equals(796993873408264695, invert(p1, p2));
    Expect.equals(2302612976619580647501352961102487476, invert(p3*p4, p5*p6));

    Expect.throws(() => invert(p1 * p2, p2 * p3),
      (e) => e is IntegerDivisionByZeroException);

    // Negatives
    Expect.equals(12667645130360889712, invert(-p1, p2));
    Expect.equals(796993873408264695, invert(p1, -p2));
    Expect.equals(12667645130360889712, invert(-p1, -p2));
  }

  void testLcmWithBigints() {
    Expect.equals(pow(2, 64)*3*5*7, lcm(pow(2, 64)*3*5, pow(2,63)*3*7));
    // 595056260442243647 is the first prime after 2**64 / 31.
    Expect.equals(31*37*595056260442243647,
      lcm(31*595056260442243647, 37*595056260442243647));

    Expect.equals(p1 * p2, lcm(p1, p2));
    Expect.equals(p1 * p2 * p3, lcm(p1 * p2, p2 * p3));
    Expect.equals(p4 * p5, lcm(p4 * p5, p4));

    // Negative
    Expect.equals(p1 * p2, lcm(-p1, p2));
    Expect.equals(p1 * p2, lcm(p1, -p2));
    Expect.equals(p1 * p2, lcm(-p1, -p2));
  }

  void testPowmodWithBigints() {
    // A modulus value greater than 94906265 can result in an intermediate step
    // evaluating to a bigint (base * base).
    // 9079837958533 is the first prime after 2**48 / 31.
    Expect.equals(1073741824, powmod(pow(2, 30), 1, 9079837958533));
    Expect.equals(9079822119301, powmod(pow(2, 30), 2, 9079837958533));
    Expect.equals(8370475851674, powmod(pow(2, 30), 3, 9079837958533));
    Expect.equals(5725645469433, powmod(pow(2, 30), 4, 9079837958533));

    // bigint base
    Expect.equals(10435682577172878912, powmod(p1, 31, p2));
    Expect.equals(2171334335785523204, powmod(p1 * p2, 5, p3));
    Expect.equals(2075559997960884603, powmod(p1 * 120, 8, p2));

    // bigint exponent
    Expect.equals(236325130834703514, powmod(pow(2, 64), p1, p4));
    Expect.equals(1733635560285390571, powmod(1000000, p5, p6));

    // bigint modulus
    Expect.equals(4740839599282053976, powmod(p7, p8, p1));
    Expect.equals(13037487407831899228197227177643459429,
      powmod(p2, p3, p4 * p5));

    // Negative
    Expect.equals(3028956426596275495, powmod(-p1, 31, p2));
    Expect.equals(5719988737977477486, powmod(p1, -31, p2));
    Expect.equals(10435682577172878912, powmod(p1, 31, -p2));
    Expect.equals(7744650265791676921, powmod(-p1, -31, p2));
    Expect.equals(3028956426596275495, powmod(-p1, 31, -p2));
    Expect.equals(5719988737977477486, powmod(p1, -31, -p2));
    Expect.equals(7744650265791676921, powmod(-p1, -31, -p2));
  }

  testMain() {
    // Source for expected values is Wolfram Alpha (presumably just GMP).
    testGcdWithBigints();
    testGcdextWithBigints();
    testInvertWithBigints();
    testLcmWithBigints();
    testPowmodWithBigints();
  }
}

main() {
  new BigintTest().testMain();
}
