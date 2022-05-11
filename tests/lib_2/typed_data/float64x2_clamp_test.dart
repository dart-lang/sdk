// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--intrinsify --optimization-counter-threshold=10 --no-background-compilation
// VMOptions=--no-intrinsify --optimization-counter-threshold=10 --no-background-compilation

// @dart = 2.9

// Library tag to be able to run in html test framework.
library float64x2_clamp_test;

import 'dart:math';
import 'dart:typed_data';
import 'package:expect/expect.dart';

void testClampLowerGreaterThanUpper() {
  Float64x2 l = new Float64x2(1.0, 1.0);
  Float64x2 u = new Float64x2(-1.0, -1.0);
  Float64x2 z = new Float64x2.zero();
  Float64x2 a = z.clamp(l, u);
  Expect.equals(a.x, 1.0);
  Expect.equals(a.y, 1.0);
}

void testClamp() {
  Float64x2 l = new Float64x2(-1.0, -1.0);
  Float64x2 u = new Float64x2(1.0, 1.0);
  Float64x2 z = new Float64x2.zero();
  Float64x2 a = z.clamp(l, u);
  Expect.equals(a.x, 0.0);
  Expect.equals(a.y, 0.0);
}

void testNonZeroClamp() {
  Float64x2 l = new Float64x2(-pow(123456.789, 123.1) as double, -234567.89);
  Float64x2 u = new Float64x2(pow(123456.789, 123.1) as double, 234567.89);
  Float64x2 v =
      new Float64x2(-pow(123456789.123, 123.1) as double, 234567890.123);
  Float64x2 a = v.clamp(l, u);
  Expect.equals(a.x, -pow(123456.789, 123) as double);
  Expect.equals(a.y, 234567.89);
}

Float64x2 negativeZeroClamp() {
  final negZero = -Float64x2.zero();
  return negZero.clamp(negZero, Float64x2.zero());
}

Float64x2 zeroClamp() {
  final negOne = -Float64x2(1.0, 1.0);
  return Float64x2.zero().clamp(negOne, -Float64x2.zero());
}

void testNegativeZeroClamp(Float64x2 unopt) {
  final res = negativeZeroClamp();
  Expect.equals(res.x.compareTo(unopt.x), 0);
  Expect.equals(res.y.compareTo(unopt.y), 0);
}

void testZeroClamp(Float64x2 unopt) {
  final res = zeroClamp();
  Expect.equals(res.x.compareTo(unopt.x), 0);
  Expect.equals(res.y.compareTo(unopt.y), 0);
}

main() {
  final unoptNegZeroClamp = negativeZeroClamp();
  final unoptZeroClamp = zeroClamp();
  for (int i = 0; i < 2000; i++) {
    testClampLowerGreaterThanUpper();
    testClamp();
    testNonZeroClamp();
    testNegativeZeroClamp(unoptNegZeroClamp);
    testZeroClamp(unoptZeroClamp);
  }
}
