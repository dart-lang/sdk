// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing the instanceof operation.

library intrinsified_methods_test;

import "package:expect/expect.dart";
import 'dart:math';

testIsNegative() {
  Expect.isFalse((12.0).isNegative);
  Expect.isTrue((-12.0).isNegative);
  Expect.isFalse((double.nan).isNegative);
  Expect.isFalse((0.0).isNegative);
  Expect.isTrue((-0.0).isNegative);
  Expect.isFalse((double.infinity).isNegative);
  Expect.isTrue((double.negativeInfinity).isNegative);
}

testIsNaN() {
  Expect.isFalse((1.0).isNaN);
  Expect.isTrue((double.nan).isNaN);
}

testTrigonometric() {
  Expect.approxEquals(1.0, sin(PI / 2.0), 0.0001);
  Expect.approxEquals(1.0, cos(0), 0.0001);
  Expect.approxEquals(1.0, cos(0.0), 0.0001);
}

num foo(int n) {
  var x;
  for (var i = 0; i <= n; ++i) {
    Expect.equals(2.0, sqrt(4.0));
    testIsNegative();
    testIsNaN();
    testTrigonometric();
  }
  return x;
}

void main() {
  var m = foo(4000);
}
