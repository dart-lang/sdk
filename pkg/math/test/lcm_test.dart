// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library math_test;
import "package:expect/expect.dart";
import 'dart:math';
import 'package:math/math.dart';

void testLcm() {
  Expect.equals(0, lcm(0, 7));
  Expect.equals(0, lcm(5, 0));
  Expect.equals(0, lcm(-5, 0));
  Expect.equals(0, lcm(0, 0));
  Expect.equals(35, lcm(5, 7));
  Expect.equals(36, lcm(12, 18));
  Expect.equals(36, lcm(12, -18));
  Expect.equals(36, lcm(-12, -18));
  Expect.equals(36, lcm(18, 12));
  Expect.equals(315, lcm(45, 105));

  Expect.throws(() => lcm(0, null), (e) => e is ArgumentError);
  Expect.throws(() => lcm(null, 0), (e) => e is ArgumentError);

  // Cover all branches in Binary GCD implementation.
  // 0 shared powers-of-two factors.
  Expect.equals(28, lcm(2*2, 7));
  // 1 shared power-of-two factor.
  Expect.equals(28, lcm(2*2, 2*7));
  // >1 shared powers-of-two factors.
  Expect.equals(120, lcm(2*2*2*3, 2*2*2*5));

  // 0 remaining powers-of-two in a.
  Expect.equals(18, lcm(2*3, 2*3*3));
  // 1 remaining power-of-two in a.
  Expect.equals(36, lcm(2*2*3, 2*3*3));
  // >1 remaining powers-of-two in a.
  Expect.equals(144, lcm(2*2*2*2*3, 2*3*3));

  // 0 remaining powers-of-two in b.
  Expect.equals(18, lcm(2*3, 2*3*3));
  // 1 remaining power-of-two in b.
  Expect.equals(12, lcm(2*3, 2*2*3));
  // >1 remaining powers-of-two in b.
  Expect.equals(72, lcm(2*3, 2*2*2*3*3));

  // Innermost 'if'
  // a > b.
  Expect.equals(60, lcm(2*2*3*5, 2*3));
  // a == b.
  Expect.equals(24, lcm(2*3, 2*2*2*3));
  // a < b.
  Expect.equals(84, lcm(2*3, 2*2*3*7));

  // do while loop executions.
  // Executed 1 time.
  Expect.equals(24, lcm(2*3, 2*2*2*3));
  // Executed >1 times.
  Expect.equals(180, lcm(2*3*3, 2*2*3*5));

  // Medium int (mint) arguments.
  Expect.equals(pow(2, 62)*3, lcm(pow(2, 61)*3, pow(2,62)));
  // 9079837958533 is the first prime after 2**48 / 31.
  Expect.equals(31*37*9079837958533,
    lcm(31*9079837958533, 37*9079837958533));
}

main() {
  testLcm();
}
