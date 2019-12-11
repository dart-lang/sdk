// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

library arithmetic_test;

import "package:expect/expect.dart";
import 'dart:math';

class ArithmeticTest {
  static runOne() {
    // Math functions.
    Expect.equals(1234567890123456789, int.parse("1234567890123456789"));
    Expect.equals(-1234567890123456789, int.parse("-1234567890123456789"));
    Expect.equals(9223372036854775807, int.parse("9223372036854775807"));
    Expect.equals(-9223372036854775808, int.parse("-9223372036854775808"));
  }

  static testMain() {
    runOne();
  }
}

main() {
  ArithmeticTest.testMain();
}
