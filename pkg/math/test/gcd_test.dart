// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library math_test;
import "package:expect/expect.dart";
import 'dart:math';
import 'package:math/math.dart';

void testGcd() {
  Expect.equals(7, gcd(0, 7));
  Expect.equals(5, gcd(5, 0));
  Expect.equals(5, gcd(-5, 0));
  Expect.equals(0, gcd(0, 0));
  Expect.equals(1, gcd(5, 7));
  Expect.equals(6, gcd(12, 18));
  Expect.equals(6, gcd(12, -18));
  Expect.equals(6, gcd(-12, -18));
  Expect.equals(6, gcd(18, 12));
  Expect.equals(15, gcd(45, 105));

  Expect.throws(() => gcd(0, null), (e) => e is ArgumentError);
  Expect.throws(() => gcd(null, 0), (e) => e is ArgumentError);

  // Cover all branches in Binary GCD implementation.
  // 0 shared powers-of-two factors.
  Expect.equals(1, gcd(2*2, 7));
  // 1 shared power-of-two factor.
  Expect.equals(2, gcd(2*2, 2*7));
  // >1 shared powers-of-two factors.
  Expect.equals(8, gcd(2*2*2*3, 2*2*2*5));

  // 0 remaining powers-of-two in a.
  Expect.equals(6, gcd(2*3, 2*3*3));
  // 1 remaining power-of-two in a.
  Expect.equals(6, gcd(2*2*3, 2*3*3));
  // >1 remaining powers-of-two in a.
  Expect.equals(6, gcd(2*2*2*2*3, 2*3*3));

  // 0 remaining powers-of-two in b.
  Expect.equals(6, gcd(2*3, 2*3*3));
  // 1 remaining power-of-two in b.
  Expect.equals(6, gcd(2*3, 2*2*3));
  // >1 remaining powers-of-two in b.
  Expect.equals(6, gcd(2*3, 2*2*2*3*3));

  // Innermost 'if'
  // a > b.
  Expect.equals(6, gcd(2*2*3*5, 2*3));
  // a == b.
  Expect.equals(6, gcd(2*3, 2*2*2*3));
  // a < b.
  Expect.equals(6, gcd(2*3, 2*2*3*7));

  // do while loop executions.
  // Executed 1 time.
  Expect.equals(6, gcd(2*3, 2*2*2*3));
  // Executed >1 times.
  Expect.equals(6, gcd(2*3*3, 2*2*3*5));

  // Medium int (mint) arguments.
  Expect.equals(pow(2, 61), gcd(pow(2, 61)*3, pow(2,62)));
  // 9079837958533 is the first prime after 2**48 / 31.
  Expect.equals(9079837958533,
    gcd(31*9079837958533, 37*9079837958533));
}

main() {
  testGcd();
}
