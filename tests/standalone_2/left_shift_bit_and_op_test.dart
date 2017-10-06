// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests optimizing (a << b) & c if c is a Smi constant.

import "package:expect/expect.dart";

main() {
  checkshiftAnd32();
  checkShiftAnd64();
  // Optimize shiftAnd32.
  for (int i = 0; i < 10000; i++) {
    A.shiftAnd32(12, 17);
    A.shiftAnd64(12, 17);
    Expect.equals(72, A.multipleConstantUses(3, 4));
    Expect.equals(34493956096, A.multipleShiftUse(134742016, 8));
  }
  checkshiftAnd32();
  checkShiftAnd64();

  Expect.throws(() => A.shiftAnd32(12, -5));

  // Check environment dependency.
  final a = new A(), b = new B();
  for (var i = 0; i < 10000; i++) {
    Expect.equals(0, bar(a));
  }
  Expect.equals(4294967296, bar(b));
}

checkshiftAnd32() {
  Expect.equals(1572864, A.shiftAnd32(12, 17));
  Expect.equals(12, A.shiftAnd32(12, 0));
  Expect.equals(285212672, A.shiftAnd32(16779392, 17));
}

checkShiftAnd64() {
  Expect.equals(1125936481173504, A.shiftAnd64(4611694814806147072, 7));
}

class A {
  static const int MASK_32 = (1 << 30) - 1;
  static const int MASK_64 = (1 << 62) - 1;

  static shiftAnd32(a, c) {
    return (a << c) & MASK_32;
  }

  static shiftAnd64(a, c) {
    return (a << c) & MASK_64;
  }

  static multipleConstantUses(a, c) {
    var j = (a << c) & 0xFF;
    var k = (a << 3) & 0xFF;
    return j + k;
  }

  // Make sure that left shift is nor marked as truncating.
  static multipleShiftUse(a, c) {
    var y = (a << c);
    var x = y & 0x7F;
    return y + x;
  }

  foo(x) {
    return x & 0xf;
  }
}

class B {
  foo(x) {
    return x;
  }
}

bar(o) {
  return o.foo(1 << 32);
}
