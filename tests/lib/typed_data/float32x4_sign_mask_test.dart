// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library float32x4_sign_mask;

import 'dart:typed_data';

import 'package:expect/expect.dart';

void testImmediates() {
  Expect.equals(0x0, Float32x4(1.0, 2.0, 3.0, 4.0).signMask);
  Expect.equals(0xf, Float32x4(-1.0, -2.0, -3.0, -0.0).signMask);
  Expect.equals(0x1, Float32x4(-1.0, 2.0, 3.0, 4.0).signMask);
  Expect.equals(0x2, Float32x4(1.0, -2.0, 3.0, 4.0).signMask);
  Expect.equals(0x4, Float32x4(1.0, 2.0, -3.0, 4.0).signMask);
  Expect.equals(0x8, Float32x4(1.0, 2.0, 3.0, -4.0).signMask);
}

void testZero() {
  Expect.equals(0x0, Float32x4(0.0, 0.0, 0.0, 0.0).signMask);
  Expect.equals(0xf, Float32x4(-0.0, -0.0, -0.0, -0.0).signMask);
}

void testArithmetic() {
  final a = Float32x4(1.0, 1.0, 1.0, 1.0);
  final b = Float32x4(2.0, 2.0, 2.0, 2.0);
  final c = Float32x4(-1.0, -1.0, -1.0, -1.0);
  Expect.equals(0xf, (a - b).signMask);
  Expect.equals(0x0, (b - a).signMask);
  Expect.equals(0x0, (c * c).signMask);
  Expect.equals(0xf, (a * c).signMask);
}

// Check every one of the 16 sign-bit patterns: lane i is negative when bit i of
// `mask` is set, so signMask should return `mask`.
void testExhaustive() {
  for (int mask = 0; mask < 16; mask++) {
    double lane(int i) => (mask & (1 << i)) != 0 ? -1.0 : 1.0;
    Expect.equals(mask, Float32x4(lane(0), lane(1), lane(2), lane(3)).signMask);
  }
}

void testSpecialValues() {
  const inf = double.infinity;
  Expect.equals(0x0, Float32x4(inf, inf, inf, inf).signMask);
  Expect.equals(0xf, Float32x4(-inf, -inf, -inf, -inf).signMask);
  Expect.equals(0x5, Float32x4(-inf, 1.0, -inf, 1.0).signMask);
  // NaN is intentionally not tested. The sign bit of a NaN is not portable
  // across architectures or the web backends.
  Expect.equals(0xf, Float32x4(-1e-40, -1e-40, -1e-40, -1e-40).signMask);
}

main() {
  for (int i = 0; i < 2000; i++) {
    testImmediates();
    testZero();
    testArithmetic();
    testExhaustive();
    testSpecialValues();
  }
}
