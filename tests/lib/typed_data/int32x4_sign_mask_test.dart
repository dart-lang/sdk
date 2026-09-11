// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library int32x4_sign_mask;

import 'dart:typed_data';

import 'package:expect/expect.dart';

void testImmediates() {
  Expect.equals(0x0, Int32x4(1, 2, 3, 4).signMask);
  Expect.equals(0xf, Int32x4(-1, -2, -3, -4).signMask);
  Expect.equals(0x1, Int32x4.bool(true, false, false, false).signMask);
  Expect.equals(0x2, Int32x4.bool(false, true, false, false).signMask);
  Expect.equals(0x4, Int32x4.bool(false, false, true, false).signMask);
  Expect.equals(0x8, Int32x4.bool(false, false, false, true).signMask);
}

void testZero() {
  Expect.equals(0x0, Int32x4.zero().signMask);
  Expect.equals(0x0, Int32x4(-0, -0, -0, -0).signMask);
}

void testLogic() {
  final a = Int32x4(0x80000000, 0x80000000, 0x80000000, 0x80000000);
  final b = Int32x4(0x70000000, 0x70000000, 0x70000000, 0x70000000);
  final c = Int32x4(0xf0000000, 0xf0000000, 0xf0000000, 0xf0000000);
  Expect.equals(0xf, (a & c).signMask);
  Expect.equals(0x0, (a & b).signMask);
  Expect.equals(0xf, (b ^ a).signMask);
  Expect.equals(0xf, (b | c).signMask);
}

// Check every one of the 16 sign-bit patterns: lane i is negative when bit i of
// `mask` is set, so signMask should return `mask`. Positive lanes use 0x7fffffff
// (all bits but the sign) to confirm only the sign bit is read.
void testExhaustive() {
  for (int mask = 0; mask < 16; mask++) {
    int lane(int i) => (mask & (1 << i)) != 0 ? 0x80000000 : 0x7fffffff;
    Expect.equals(mask, Int32x4(lane(0), lane(1), lane(2), lane(3)).signMask);
  }
}

main() {
  for (int i = 0; i < 2000; i++) {
    testImmediates();
    testZero();
    testLogic();
    testExhaustive();
  }
}
