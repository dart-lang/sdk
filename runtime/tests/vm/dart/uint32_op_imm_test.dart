// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data";

@pragma("vm:never-inline")
void and1(Uint32List list) {
  list[0] &= 1;
}

@pragma("vm:never-inline")
void or1(Uint32List list) {
  list[0] |= 1;
}

@pragma("vm:never-inline")
void xor1(Uint32List list) {
  list[0] ^= 1;
}

@pragma("vm:never-inline")
void add1(Uint32List list) {
  list[0] += 1;
}

@pragma("vm:never-inline")
void sub1(Uint32List list) {
  list[0] -= 1;
}

@pragma("vm:never-inline")
void mul1(Uint32List list) {
  list[0] *= 1;
}

@pragma("vm:never-inline")
void and2(Uint32List list) {
  list[0] &= 2;
}

@pragma("vm:never-inline")
void or2(Uint32List list) {
  list[0] |= 2;
}

@pragma("vm:never-inline")
void xor2(Uint32List list) {
  list[0] ^= 2;
}

@pragma("vm:never-inline")
void add2(Uint32List list) {
  list[0] += 2;
}

@pragma("vm:never-inline")
void sub2(Uint32List list) {
  list[0] -= 2;
}

@pragma("vm:never-inline")
void mul2(Uint32List list) {
  list[0] *= 2;
}

@pragma("vm:never-inline")
void and7(Uint32List list) {
  list[0] &= 7;
}

@pragma("vm:never-inline")
void or7(Uint32List list) {
  list[0] |= 7;
}

@pragma("vm:never-inline")
void xor7(Uint32List list) {
  list[0] ^= 7;
}

@pragma("vm:never-inline")
void add7(Uint32List list) {
  list[0] += 7;
}

@pragma("vm:never-inline")
void sub7(Uint32List list) {
  list[0] -= 7;
}

@pragma("vm:never-inline")
void mul7(Uint32List list) {
  list[0] *= 7;
}

@pragma("vm:never-inline")
void andH(Uint32List list) {
  list[0] &= 0x7FFFFFF;
}

@pragma("vm:never-inline")
void orH(Uint32List list) {
  list[0] |= 0x7FFFFFF;
}

@pragma("vm:never-inline")
void xorH(Uint32List list) {
  list[0] ^= 0x7FFFFFF;
}

@pragma("vm:never-inline")
void addH(Uint32List list) {
  list[0] += 0x7FFFFFF;
}

@pragma("vm:never-inline")
void subH(Uint32List list) {
  list[0] -= 0x7FFFFFF;
}

@pragma("vm:never-inline")
void mulH(Uint32List list) {
  list[0] *= 0x7FFFFFF;
}

expect(int observed, int expected) {
  if (observed != expected) {
    throw "0x${observed.toRadixString(16)}";
  }
}

main() {
  Uint32List u32 = Uint32List(1);

  u32[0] = 0x12345678;
  and1(u32);
  expect(u32[0], 0);
  u32[0] = 0x87654321;
  and1(u32);
  expect(u32[0], 1);
  u32[0] = 0x12345678;
  or1(u32);
  expect(u32[0], 0x12345679);
  u32[0] = 0x87654321;
  or1(u32);
  expect(u32[0], 0x87654321);
  u32[0] = 0x12345678;
  xor1(u32);
  expect(u32[0], 0x12345679);
  u32[0] = 0x87654321;
  xor1(u32);
  expect(u32[0], 0x87654320);
  u32[0] = 0x12345678;
  add1(u32);
  expect(u32[0], 0x12345679);
  u32[0] = 0x87654321;
  add1(u32);
  expect(u32[0], 0x87654322);
  u32[0] = 0x12345678;
  sub1(u32);
  expect(u32[0], 0x12345677);
  u32[0] = 0x87654321;
  sub1(u32);
  expect(u32[0], 0x87654320);
  u32[0] = 0x12345678;
  mul1(u32);
  expect(u32[0], 0x12345678);
  u32[0] = 0x87654321;
  mul1(u32);
  expect(u32[0], 0x87654321);

  u32[0] = 0x12345678;
  and2(u32);
  expect(u32[0], 0);
  u32[0] = 0x87654321;
  and2(u32);
  expect(u32[0], 0);
  u32[0] = 0x12345678;
  or2(u32);
  expect(u32[0], 0x1234567a);
  u32[0] = 0x87654321;
  or2(u32);
  expect(u32[0], 0x87654323);
  u32[0] = 0x12345678;
  xor2(u32);
  expect(u32[0], 0x1234567a);
  u32[0] = 0x87654321;
  xor2(u32);
  expect(u32[0], 0x87654323);
  u32[0] = 0x12345678;
  add2(u32);
  expect(u32[0], 0x1234567a);
  u32[0] = 0x87654321;
  add2(u32);
  expect(u32[0], 0x87654323);
  u32[0] = 0x12345678;
  sub2(u32);
  expect(u32[0], 0x12345676);
  u32[0] = 0x87654321;
  sub2(u32);
  expect(u32[0], 0x8765431f);
  u32[0] = 0x12345678;
  mul2(u32);
  expect(u32[0], 0x2468acf0);
  u32[0] = 0x87654321;
  mul2(u32);
  expect(u32[0], 0x0eca8642);

  u32[0] = 0x12345678;
  and7(u32);
  expect(u32[0], 0);
  u32[0] = 0x87654321;
  and7(u32);
  expect(u32[0], 1);
  u32[0] = 0x12345678;
  or7(u32);
  expect(u32[0], 0x1234567f);
  u32[0] = 0x87654321;
  or7(u32);
  expect(u32[0], 0x87654327);
  u32[0] = 0x12345678;
  xor7(u32);
  expect(u32[0], 0x1234567f);
  u32[0] = 0x87654321;
  xor7(u32);
  expect(u32[0], 0x87654326);
  u32[0] = 0x12345678;
  add7(u32);
  expect(u32[0], 0x1234567f);
  u32[0] = 0x87654321;
  add7(u32);
  expect(u32[0], 0x87654328);
  u32[0] = 0x12345678;
  sub7(u32);
  expect(u32[0], 0x12345671);
  u32[0] = 0x87654321;
  sub7(u32);
  expect(u32[0], 0x8765431a);
  u32[0] = 0x12345678;
  mul7(u32);
  expect(u32[0], 0x7f6e5d48);
  u32[0] = 0x87654321;
  mul7(u32);
  expect(u32[0], 0xb3c4d5e7);

  u32[0] = 0x12345678;
  andH(u32);
  expect(u32[0], 0x02345678);
  u32[0] = 0x87654321;
  andH(u32);
  expect(u32[0], 0x07654321);
  u32[0] = 0x12345678;
  orH(u32);
  expect(u32[0], 0x17ffffff);
  u32[0] = 0x87654321;
  orH(u32);
  expect(u32[0], 0x87ffffff);
  u32[0] = 0x12345678;
  xorH(u32);
  expect(u32[0], 0x15cba987);
  u32[0] = 0x87654321;
  xorH(u32);
  expect(u32[0], 0x809abcde);
  u32[0] = 0x12345678;
  addH(u32);
  expect(u32[0], 0x1a345677);
  u32[0] = 0x87654321;
  addH(u32);
  expect(u32[0], 0x8f654320);
  u32[0] = 0x12345678;
  subH(u32);
  expect(u32[0], 0x0a345679);
  u32[0] = 0x87654321;
  subH(u32);
  expect(u32[0], 0x7f654322);
  u32[0] = 0x12345678;
  mulH(u32);
  expect(u32[0], 0xadcba988);
  u32[0] = 0x87654321;
  mulH(u32);
  expect(u32[0], 0x809abcdf);
}
