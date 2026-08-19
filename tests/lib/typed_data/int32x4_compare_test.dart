// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library int32x4_compare;

import 'dart:typed_data';

import 'package:expect/expect.dart';

void testEqual() {
  final a = Int32x4(1, 2, 3, 4);

  // All lanes equal -> every lane is -1.
  final all = a.equal(Int32x4(1, 2, 3, 4));
  Expect.equals(-1, all.x);
  Expect.equals(-1, all.y);
  Expect.equals(-1, all.z);
  Expect.equals(-1, all.w);
  Expect.equals(0xf, all.signMask);

  // No lanes equal -> every lane is 0.
  final none = a.equal(Int32x4(5, 6, 7, 8));
  Expect.equals(0, none.x);
  Expect.equals(0, none.y);
  Expect.equals(0, none.z);
  Expect.equals(0, none.w);
  Expect.equals(0x0, none.signMask);

  // Per-lane result: only y and w match.
  final some = a.equal(Int32x4(0, 2, 0, 4));
  Expect.equals(0, some.x);
  Expect.equals(-1, some.y);
  Expect.equals(0, some.z);
  Expect.equals(-1, some.w);
  Expect.equals(0xa, some.signMask); // bits 1 and 3.
}

void testAnyTrue() {
  // Exhaustive over all 16 zero/non-zero lane combinations: anyTrue is true
  // iff at least one lane is non-zero.
  for (int bits = 0; bits < 16; bits++) {
    final v = Int32x4(
      (bits & 1) != 0 ? 1 : 0,
      (bits & 2) != 0 ? 1 : 0,
      (bits & 4) != 0 ? 1 : 0,
      (bits & 8) != 0 ? 1 : 0,
    );
    Expect.equals(bits != 0, v.anyTrue);
  }

  // anyTrue is "any bit set in any lane", not "signMask != 0" (which only
  // checks the sign bit). Int32x4(1, 0, 0, 0) distinguishes them: it is
  // non-zero but the sign bit is clear, so signMask is 0 while anyTrue is true.
  final lowBit = Int32x4(1, 0, 0, 0);
  Expect.equals(0, lowBit.signMask);
  Expect.isTrue(lowBit.anyTrue);

  // All lanes non-zero -> true.
  Expect.isTrue(Int32x4(-1, -1, -1, -1).anyTrue);

  // Consistent with the comparison mask: a match makes anyTrue true.
  final a = Int32x4(1, 2, 3, 4);
  Expect.isFalse(a.equal(Int32x4(5, 6, 7, 8)).anyTrue);
  Expect.isTrue(a.equal(Int32x4(0, 2, 0, 0)).anyTrue);
  Expect.isTrue(a.equal(a).anyTrue);

  // Equivalent to the disjunction of the lane flags.
  final m = a.equal(Int32x4(0, 2, 0, 4));
  Expect.equals(m.flagX || m.flagY || m.flagZ || m.flagW, m.anyTrue);
}

void main() {
  for (int i = 0; i < 20; i++) {
    testEqual();
    testAnyTrue();
  }
}
