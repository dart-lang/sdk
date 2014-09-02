// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library math_test;
import "package:expect/expect.dart";
import 'dart:math';
import 'package:math/math.dart';

void testInvert() {
  Expect.equals(1, invert(1, 7));
  Expect.equals(4, invert(2, 7));
  Expect.equals(5, invert(3, 7));
  Expect.equals(2, invert(4, 7));
  Expect.equals(3, invert(5, 7));
  Expect.equals(6, invert(6, 7));

  Expect.throws(() => invert(0, null), (e) => e is ArgumentError);
  Expect.throws(() => invert(null, 0), (e) => e is ArgumentError);
  Expect.throws(() => invert(0, 7), (e) => e is IntegerDivisionByZeroException);
  Expect.throws(() => invert(3, 6), (e) => e is IntegerDivisionByZeroException);
  Expect.throws(() => invert(6, 3), (e) => e is IntegerDivisionByZeroException);
  Expect.throws(() => invert(6, 0), (e) => e is IntegerDivisionByZeroException);

  // Medium int (mint) arguments.
  Expect.equals(7291109880702, invert(1000, 9079837958533));
  Expect.equals(6417656708605, invert(1000000, 9079837958533));
}

main() {
  testInvert();
}
