// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library math_test;
import "package:expect/expect.dart";
import 'dart:math';
import 'package:math/math.dart';

void testGcdext() {
  Expect.listEquals([7, 0, 1], gcdext(0, 7));
  Expect.listEquals([5, 1, 0], gcdext(5, 0));
  Expect.listEquals([5, -1, 0], gcdext(-5, 0));
  Expect.listEquals([0, 1, 0], gcdext(0, 0));
  Expect.listEquals([1, 3, -2], gcdext(5, 7));
  Expect.listEquals([6, -1, 1], gcdext(12, 18));
  Expect.listEquals([6, -1, -1], gcdext(12, -18));
  Expect.listEquals([6, 1, -1], gcdext(-12, -18));
  Expect.listEquals([6, 1, -1], gcdext(18, 12));
  Expect.listEquals([15, -2, 1], gcdext(45, 105));

  Expect.throws(() => gcdext(0, null), (e) => e is ArgumentError);
  Expect.throws(() => gcdext(null, 0), (e) => e is ArgumentError);

  // Cover all branches in Binary GCD implementation.

  // Medium int (mint) arguments.
  Expect.listEquals([pow(2, 60), 1, -1], gcdext(pow(2, 60)*5, pow(2, 62)));
  Expect.listEquals([4000000000000, -96078, 96077],
    gcdext(2305844000000000000, 2305868000000000000));
  // 9079837958533 is the first prime after 2**48 / 31.
  Expect.listEquals([9079837958533, 6, -5],
    gcdext(31*9079837958533, 37*9079837958533));
}

main() {
  testGcdext();
}
