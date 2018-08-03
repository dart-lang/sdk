// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing bitwise operations.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation --enable-inlining-annotations

import "package:expect/expect.dart";

const neverInline = "NeverInline";

void main() {
  for (int i = 0; i < 4; i++) {
    test();
  }
}

void test() {
  Expect.equals(3, (3 & 7));
  Expect.equals(7, (3 | 7));
  Expect.equals(4, (3 ^ 7));
  Expect.equals(25, (100 >> 2));
  Expect.equals(400, (100 << 2));
  Expect.equals(-25, (-100 >> 2));
  Expect.equals(-101, ~100);
  Expect.equals(0, 1 << 64);
  Expect.equals(0, -1 << 64);
  Expect.equals(0x40000000, 0x04000000 << 4);
  Expect.equals(0x4000000000000000, 0x0400000000000000 << 4);
  Expect.equals(0, ~ -1);
  Expect.equals(-1, ~0);

  Expect.equals(0, 1 >> 160);
  Expect.equals(-1, -1 >> 160);

  Expect.equals(0x1000000000000001, 0x1000000000000001 & 0x1000100F00000001);
  Expect.equals(0x1, 0x1 & 0x1000100F00000001);
  Expect.equals(0x1, 0x1000100F00000001 & 0x1);

  Expect.equals(0x1000100F00000001, 0x1000000000000001 | 0x1000100F00000001);
  Expect.equals(0x1000100F00000011, 0x11 | 0x1000100F00000001);
  Expect.equals(0x1000100F00000011, 0x1000100F00000001 | 0x11);

  Expect.equals(0x0F00000000000000, 0x0F00000000000001 ^ 0x0000000000000001);
  Expect.equals(0x31, 0x0F00000000000001 ^ 0x0F00000000000030);
  Expect.equals(0x0F00000000000031, 0x0F00000000000001 ^ 0x30);
  Expect.equals(0x0F00000000000031, 0x30 ^ 0x0F00000000000001);

  Expect.equals(0x000000000000000F, 0x000000000000000F7 >> 4);
  Expect.equals(15, 0xF00000000 >> 32);
  Expect.equals(1030792151040, 16492674416655 >> 4);

  Expect.equals(0x00000000000000F0, 0xF00000000000000F << 4);
  Expect.equals(0xF00000000, 15 << 32);

  testNegativeValueShifts();
  testPositiveValueShifts();
  testNoMaskingOfShiftCount();
  testNegativeCountShifts();
  for (int i = 0; i < 20; i++) {
    testCornerCasesRightShifts();
    testRightShift64Bit();
    testLeftShift64Bit();
    testLeftShift64BitWithOverflow1();
    testLeftShift64BitWithOverflow2();
    testLeftShift64BitWithOverflow3();
  }

  // Test precedence.
  testPrecedence(4, 5, 3, 1);
  testPrecedence(3, 4, 5, 9);
  testPrecedence(0x5c71, 0x6b92, 0x7654, 0x7d28);

  // Test more special cases.
  testRightShift65();
}

void testCornerCasesRightShifts() {
  var v32 = 0xFF000000;
  var v64 = 0xFF00000000000000;
  Expect.equals(0x3, v32 >> 0x1E);
  Expect.equals(0x1, v32 >> 0x1F);
  Expect.equals(0x0, v32 >> 0x20);
  Expect.equals(-1, v64 >> 0x3E);
  Expect.equals(-1, v64 >> 0x3F);
  Expect.equals(-1, v64 >> 0x40);
}

void testRightShift64Bit() {
  var t = 0x1ffffffff;
  Expect.equals(0xffffffff, t >> 1);
}

void testLeftShift64Bit() {
  var t = 0xffffffff;
  Expect.equals(0xffffffff, t << 0);
  Expect.equals(0x1fffffffe, t << 1);
  Expect.equals(0x7fffffff80000000, t << 31);
  Expect.equals(0x8000000000000000, (t + 1) << 31);
}

void testLeftShift64BitWithOverflow1() {
  var t = 0xffffffff;
  Expect.equals(0, 2 * (t + 1) << 31); //# 03: ok
}

void testLeftShift64BitWithOverflow2() {
  var t = 0xffffffff;
  Expect.equals(0, 4 * (t + 1) << 31); //# 04: ok
}

void testLeftShift64BitWithOverflow3() {
  var t = 0xffffffff;
  Expect.equals(0x8000000000000000, (t + 1) << 31);
}

void testNegativeCountShifts() {
  bool throwOnLeft(a, b) {
    try {
      var x = a << b;
      return false;
    } catch (e) {
      return true;
    }
  }

  bool throwOnRight(a, b) {
    try {
      var x = a >> b;
      return false;
    } catch (e) {
      return true;
    }
  }

  Expect.isTrue(throwOnLeft(12, -3));
  Expect.isTrue(throwOnRight(12, -3));
  for (int i = 0; i < 20; i++) {
    Expect.isFalse(throwOnLeft(12, 3));
    Expect.isFalse(throwOnRight(12, 3));
  }
}

void testNegativeValueShifts() {
  for (int value = 0; value > -100; value--) {
    for (int i = 0; i < 300; i++) {
      int b = (value << i) >> i;
      if (i < (64 - value.bitLength)) {
        // No bits lost.
        Expect.equals(value, b);
      } else if (i >= 64) {
        // All bits are shifted out.
        Expect.equals(0, b);
      } else {
        // Some bits are lost.
        int masked_value = value & ((1 << (64 - i)) - 1);
        int signbit = masked_value & (1 << (63 - i));
        int signmask = (signbit != 0) ? (-1 << (64 - i)) : 0;
        Expect.equals(signmask | masked_value, b);
      }
    }
  }
}

void testPositiveValueShifts() {
  for (int value = 0; value < 100; value++) {
    for (int i = 0; i < 300; i++) {
      int b = (value << i) >> i;
      if (i < (64 - value.bitLength)) {
        Expect.equals(value, b);
      } else if (i >= 64) {
        Expect.equals(0, b);
      } else {
        // Some bits are lost.
        int masked_value = value & ((1 << (64 - i)) - 1);
        int signbit = masked_value & (1 << (63 - i));
        int signmask = (signbit != 0) ? (-1 << (64 - i)) : 0;
        Expect.equals(signmask | masked_value, b);
      }
    }
  }
}

void testNoMaskingOfShiftCount() {
  // Shifts which would behave differently if shift count was masked into a
  // range.
  Expect.equals(0, 0 >> 256);
  Expect.equals(0, 1 >> 256);
  Expect.equals(0, 2 >> 256);
  Expect.equals(0, shiftRight(0, 256));
  Expect.equals(0, shiftRight(1, 256));
  Expect.equals(0, shiftRight(2, 256));

  for (int shift = 1; shift <= 256; shift++) {
    Expect.equals(0, shiftRight(1, shift));
    Expect.equals(-1, shiftRight(-1, shift));
    if (shift < 63) {
      Expect.equals(true, shiftLeft(1, shift) > shiftLeft(1, shift - 1));
    } else if (shift > 64) {
      Expect.equals(
          true, (shiftLeft(1, shift) == 0) && (shiftLeft(1, shift - 1) == 0));
    }
  }
}

int shiftLeft(int a, int b) {
  return a << b;
}

int shiftRight(int a, int b) {
  return a >> b;
}

void testPrecedence(int a, int b, int c, int d) {
  // & binds stronger than ^, which binds stronger than |.
  int result = a & b ^ c | d & b ^ c;
  Expect.equals(((a & b) ^ c) | ((d & b) ^ c), result); //     &^|
  Expect.notEquals((a & (b ^ c)) | (d & (b ^ c)), result); //  ^&|
  Expect.notEquals((a & b) ^ (c | (d & b)) ^ c, result); //    &|^
  Expect.notEquals((a & b) ^ ((c | d) & b) ^ c, result); //    |&^
  Expect.notEquals(a & (b ^ (c | d)) & (b ^ c), result); //    |^&
  Expect.notEquals(a & ((b ^ c) | d) & (b ^ c), result); //    ^|&
  // Binds stronger than relational operators.
  Expect.equals((a & b) < (c & d), a & b < c & d);
  // Binds weaker than shift operators.
  Expect.equals((a & (b << c)) ^ d, a & b << c ^ d);
  Expect.notEquals((a & b) << (c ^ d), a & b << c ^ d);
}

@neverInline
rightShift65Noinline(a) => a >> 65;

testRightShift65() {
  var a = 0x5f22334455667788;
  var b = -0x5f22334455667788;

  for (var i = 0; i < 20; ++i) {
    Expect.equals(0, rightShift65Noinline(a));
    Expect.equals(-1, rightShift65Noinline(b));
  }
}
