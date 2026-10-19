// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--intrinsify --optimization-counter-threshold=10 --no-background-compilation
// VMOptions=--no-intrinsify --optimization-counter-threshold=10 --no-background-compilation

import 'dart:math';
import 'dart:typed_data';

import 'package:expect/expect.dart';

void testClampLowerGreaterThanUpper() {
  Float64x2 l = Float64x2(1.0, 1.0);
  Float64x2 u = Float64x2(-1.0, -1.0);
  Float64x2 z = Float64x2.zero();
  Float64x2 a = z.clamp(l, u);
  Expect.equals(a.x, 1.0);
  Expect.equals(a.y, 1.0);
}

void testClamp() {
  Float64x2 l = Float64x2(-1.0, -1.0);
  Float64x2 u = Float64x2(1.0, 1.0);
  Float64x2 z = Float64x2.zero();
  Float64x2 a = z.clamp(l, u);
  Expect.equals(a.x, 0.0);
  Expect.equals(a.y, 0.0);
}

void testNonZeroClamp() {
  Float64x2 l = Float64x2(-pow(123456.789, 123.1) as double, -234567.89);
  Float64x2 u = Float64x2(pow(123456.789, 123.1) as double, 234567.89);
  Float64x2 v = Float64x2(-pow(123456789.123, 123.1) as double, 234567890.123);
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

// compareTo orders -0.0 below 0.0, so it pins the sign of a zero result.
void expectLanes(Float64x2 value, double expected) {
  Expect.equals(0, value.x.compareTo(expected));
  Expect.equals(0, value.y.compareTo(expected));
}

void expectLanesNaN(Float64x2 value) {
  Expect.isTrue(value.x.isNaN);
  Expect.isTrue(value.y.isNaN);
}

void testNegativeZeroClamp(Float64x2 unopt) {
  final res = negativeZeroClamp();
  expectLanes(unopt, -0.0);
  expectLanes(res, -0.0);
}

void testZeroClamp(Float64x2 unopt) {
  final res = zeroClamp();
  expectLanes(unopt, -0.0);
  expectLanes(res, -0.0);
}

// clamp is a min followed by a max, so a NaN in any operand reaches the
// result. Which NaN it is is not specified, so only NaN-ness is checked.
void testNaNClamp() {
  final l = Float64x2(-1.0, -1.0);
  final u = Float64x2(1.0, 1.0);
  final z = Float64x2.zero();
  final n = Float64x2.splat(double.nan);
  expectLanesNaN(n.clamp(l, u));
  expectLanesNaN(z.clamp(n, u));
  expectLanesNaN(z.clamp(l, n));
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
    testNaNClamp();
  }
}
