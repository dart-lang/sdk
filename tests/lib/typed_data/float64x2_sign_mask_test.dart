// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library float64x2_sign_mask;

import 'dart:typed_data';

import 'package:expect/expect.dart';

void testImmediates() {
  Expect.equals(0x0, Float64x2(1.0, 2.0).signMask);
  Expect.equals(0x3, Float64x2(-1.0, -2.0).signMask);
  Expect.equals(0x1, Float64x2(-1.0, 2.0).signMask);
  Expect.equals(0x2, Float64x2(1.0, -2.0).signMask);
}

void testZero() {
  Expect.equals(0x0, Float64x2(0.0, 0.0).signMask);
  Expect.equals(0x3, Float64x2(-0.0, -0.0).signMask);
}

// Check every one of the 4 sign-bit patterns: lane i is negative when bit i of
// `mask` is set, so signMask should return `mask`.
void testExhaustive() {
  for (int mask = 0; mask < 4; mask++) {
    double lane(int i) => (mask & (1 << i)) != 0 ? -1.0 : 1.0;
    Expect.equals(mask, Float64x2(lane(0), lane(1)).signMask);
  }
}

void testSpecialValues() {
  const inf = double.infinity;
  Expect.equals(0x0, Float64x2(inf, inf).signMask);
  Expect.equals(0x3, Float64x2(-inf, -inf).signMask);
  Expect.equals(0x1, Float64x2(-inf, inf).signMask);
  // NaN is intentionally not tested. The sign bit of a NaN is not portable
  // across architectures or the web backends.
  Expect.equals(0x3, Float64x2(-5e-324, -5e-324).signMask);
}

main() {
  for (int i = 0; i < 2000; i++) {
    testImmediates();
    testZero();
    testExhaustive();
    testSpecialValues();
  }
}
