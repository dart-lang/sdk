// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import 'dart:typed_data';

import 'package:expect/expect.dart';

void testClampLowerGreaterThanUpper() {
  Float32x4 l = Float32x4(1.0, 1.0, 1.0, 1.0);
  Float32x4 u = Float32x4(-1.0, -1.0, -1.0, -1.0);
  Float32x4 z = Float32x4.zero();
  Float32x4 a = z.clamp(l, u);
  Expect.equals(a.x, 1.0);
  Expect.equals(a.y, 1.0);
  Expect.equals(a.z, 1.0);
  Expect.equals(a.w, 1.0);
}

void testClamp() {
  Float32x4 l = Float32x4(-1.0, -1.0, -1.0, -1.0);
  Float32x4 u = Float32x4(1.0, 1.0, 1.0, 1.0);
  Float32x4 z = Float32x4.zero();
  Float32x4 a = z.clamp(l, u);
  Expect.equals(a.x, 0.0);
  Expect.equals(a.y, 0.0);
  Expect.equals(a.z, 0.0);
  Expect.equals(a.w, 0.0);
}

Float32x4 negativeZeroClamp() {
  final negZero = -Float32x4.zero();
  return negZero.clamp(negZero, Float32x4.zero());
}

Float32x4 zeroClamp() {
  final negOne = -Float32x4(1.0, 1.0, 1.0, 1.0);
  return Float32x4.zero().clamp(negOne, -Float32x4.zero());
}

// compareTo orders -0.0 below 0.0, so it pins the sign of a zero result.
void expectLanes(Float32x4 value, double expected) {
  Expect.equals(0, value.x.compareTo(expected));
  Expect.equals(0, value.y.compareTo(expected));
  Expect.equals(0, value.z.compareTo(expected));
  Expect.equals(0, value.w.compareTo(expected));
}

void expectLanesNaN(Float32x4 value) {
  Expect.isTrue(value.x.isNaN);
  Expect.isTrue(value.y.isNaN);
  Expect.isTrue(value.z.isNaN);
  Expect.isTrue(value.w.isNaN);
}

// Regression test for https://github.com/dart-lang/sdk/issues/40426.
void testNegativeZeroClamp(Float32x4 unopt) {
  final res = negativeZeroClamp();
  expectLanes(unopt, -0.0);
  expectLanes(res, -0.0);
}

// Regression test for https://github.com/dart-lang/sdk/issues/40426.
void testZeroClamp(Float32x4 unopt) {
  final res = zeroClamp();
  expectLanes(unopt, -0.0);
  expectLanes(res, -0.0);
}

// clamp is a min followed by a max, so a NaN in any operand reaches the
// result. Which NaN it is is not specified, so only NaN-ness is checked.
void testNaNClamp() {
  final l = Float32x4(-1.0, -1.0, -1.0, -1.0);
  final u = Float32x4(1.0, 1.0, 1.0, 1.0);
  final z = Float32x4.zero();
  final n = Float32x4.splat(double.nan);
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
    testNegativeZeroClamp(unoptNegZeroClamp);
    testZeroClamp(unoptZeroClamp);
    testNaNClamp();
  }
}
