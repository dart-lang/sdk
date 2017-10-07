// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test UnboxedIntConverter for int32.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";
import "dart:typed_data";

int32_add(a, b, c) => (a * c) + (b * c);
int32_mul(a, b, c) => (a * c) * b;
int32_sub(a, b, c) => (a * c) - (b * c);
int32_shr(a, b, c) => (a * c * b) >> 16;
int32_shl(a, b, c) => (a * c * b) << 16;
int32_xor(a, b, c) => (a * c) ^ (b * c);
int32_or(a, b, c) => (a * c) | (b * c);
int32_and(a, b, c) => (a * c) & (b * c);

int32_to_mint(a, b) {
  var sum = 0;
  var j = 0;
  for (var i = a; i <= b; i++) {
    sum -= (j * ++j) & 0xff;
  }

  return 0xffffffff + sum;
}

mint_to_int32(a, c, d) {
  return a * a * a * (c - d);
}

uint32_to_int32(a, c) {
  return (a * a * a) * (c & 0xFFFFFFFF);
}

main() {
  for (var j = 0; j < 1000; j++) {
    Expect.equals(2, int32_add(1, 1, 1));
    Expect.equals(1, int32_mul(1, 1, 1));
    Expect.equals(0, int32_sub(1, 1, 1));
    Expect.equals(0, int32_shr(1, 1, 1));
    Expect.equals(1 << 16, int32_shl(1, 1, 1));
    Expect.equals(0, int32_xor(1, 1, 1));
    Expect.equals(1, int32_or(1, 1, 1));
    Expect.equals(1, int32_and(1, 1, 1));
  }

  Expect.equals(0x7ffffffe, int32_add(0x7ffffffc ~/ 2, 1, 2));
  Expect.equals(-0x80000000, int32_add(-0x7ffffffe ~/ 2, -1, 2));
  Expect.equals(-0x80000002, int32_add(-0x7ffffffe ~/ 2, -2, 2)); // Overflow.
  Expect.equals(0x7ffffffe, int32_sub(0x7ffffffc ~/ 2, -1, 2));
  Expect.equals(-0x80000000, int32_sub(-0x7ffffffe ~/ 2, 1, 2));
  Expect.equals(-0x80000002, int32_sub(-0x7ffffffe ~/ 2, 2, 2)); // Overflow.
  Expect.equals(-0x7ffffffe, int32_mul(0x7ffffffe ~/ 2, -1, 2));
  Expect.equals(-0x80000000, int32_mul(-0x80000000 ~/ 2, 1, 2));
  Expect.equals(0x80000000, int32_mul(-0x80000000 ~/ 2, -1, 2)); // Overflow.
  Expect.equals(0x60000000, int32_xor(0x40000000 ~/ 2, 0x20000000 ~/ 2, 2));
  Expect.equals(0x00000000, int32_xor(0x40000000 ~/ 2, 0x40000000 ~/ 2, 2));
  Expect.equals(0x60000000, int32_or(0x40000000 ~/ 2, 0x20000000 ~/ 2, 2));
  Expect.equals(0x60000000, int32_or(0x60000000 ~/ 2, 0x40000000 ~/ 2, 2));
  Expect.equals(0x00000000, int32_and(0x40000000 ~/ 2, 0x20000000 ~/ 2, 2));
  Expect.equals(0x40000000, int32_and(0x60000000 ~/ 2, 0x40000000 ~/ 2, 2));
  Expect.equals(1, int32_shr(1, 1 << 16, 1));
  Expect.equals(-1 << 15, int32_shr(1 << 15, -(1 << 16), 1));
  Expect.equals(-0x080000000, int32_shl(-1 << 15, 1, 1));
  Expect.equals(-0x100000000, int32_shl(-1 << 16, 1, 1)); // Overflow.

  Expect.equals(0, int32_shr(1, 1, 1));
  Expect.equals(1 << 16, int32_shl(1, 1, 1));

  for (var j = 0; j < 1000; j++) {
    Expect.equals(4294839503, int32_to_mint(0, 1000));
    Expect.equals(-8, mint_to_int32(2, 0x100000000, 0x100000001));
    Expect.equals(8, uint32_to_int32(2, 0x100000001));
  }
  Expect.equals(8 * 0x80000001, uint32_to_int32(2, 0x180000001));
}
