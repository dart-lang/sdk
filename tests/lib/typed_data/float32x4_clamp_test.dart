// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library float32x4_clamp_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

void testClampLowerGreaterThanUpper() {
  Float32x4 l = new Float32x4(1.0, 1.0, 1.0, 1.0);
  Float32x4 u = new Float32x4(-1.0, -1.0, -1.0, -1.0);
  Float32x4 z = new Float32x4.zero();
  Float32x4 a = z.clamp(l, u);
  Expect.equals(a.x, 1.0);
  Expect.equals(a.y, 1.0);
  Expect.equals(a.z, 1.0);
  Expect.equals(a.w, 1.0);
}

void testClamp() {
  Float32x4 l = new Float32x4(-1.0, -1.0, -1.0, -1.0);
  Float32x4 u = new Float32x4(1.0, 1.0, 1.0, 1.0);
  Float32x4 z = new Float32x4.zero();
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

// Regression test for https://github.com/dart-lang/sdk/issues/40426.
void testNegativeZeroClamp(Float32x4 unopt) {
  final res = negativeZeroClamp();
  Expect.equals(res.x.compareTo(unopt.x), 0);
  Expect.equals(res.y.compareTo(unopt.y), 0);
  Expect.equals(res.z.compareTo(unopt.z), 0);
  Expect.equals(res.w.compareTo(unopt.w), 0);
}

// Regression test for https://github.com/dart-lang/sdk/issues/40426.
void testZeroClamp(Float32x4 unopt) {
  final res = zeroClamp();
  Expect.equals(res.x.compareTo(unopt.x), 0);
  Expect.equals(res.y.compareTo(unopt.y), 0);
  Expect.equals(res.z.compareTo(unopt.z), 0);
  Expect.equals(res.w.compareTo(unopt.w), 0);
}

main() {
  final unoptNegZeroClamp = negativeZeroClamp();
  final unoptZeroClamp = zeroClamp();
  for (int i = 0; i < 2000; i++) {
    testClampLowerGreaterThanUpper();
    testClamp();
    testNegativeZeroClamp(unoptNegZeroClamp);
    testZeroClamp(unoptZeroClamp);
  }
}
