// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the buffer of an Int32x4List created through its constructors,
// including byte level access and views sharing the storage.

import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  testLengths();
  testByteDataReads();
  testByteDataWrites();
  testUint8View();
  testInt32x4View();
  testUnmodifiable();
  testFromListAndSetRange();
}

Int32x4List makeList() {
  final list = Int32x4List(4);
  list[0] = Int32x4(0x11223344, 0x55667788, -1, 0);
  list[3] = Int32x4(1, 2, 3, 0x7FFFFFFF);
  return list;
}

void testLengths() {
  final list = makeList();
  Expect.equals(64, list.buffer.lengthInBytes);
  Expect.equals(64, list.lengthInBytes);
  Expect.equals(0, list.offsetInBytes);
  Expect.equals(16, list.elementSizeInBytes);
}

void testByteDataReads() {
  final bd = makeList().buffer.asByteData();
  Expect.equals(0x44, bd.getUint8(0));
  Expect.equals(0x11, bd.getUint8(3));
  Expect.equals(0x88, bd.getUint8(4));
  Expect.equals(0x11223344, bd.getUint32(0, Endian.little));
  Expect.equals(0xFFFFFFFF, bd.getUint32(8, Endian.little));
  Expect.equals(0x88112233, bd.getUint32(1, Endian.little));
  Expect.equals(0x44332211, bd.getUint32(0, Endian.big));
  Expect.equals(0x7FFFFFFF, bd.getUint32(60, Endian.little));
}

void testByteDataWrites() {
  final list = makeList();
  final bd = list.buffer.asByteData();
  bd.setUint8(12, 0xAB);
  Expect.equals(0xAB, list[0].w);
  bd.setUint32(48, 0xDEADBEEF, Endian.little);
  Expect.equals(0xDEADBEEF, list[3].x & 0xFFFFFFFF);
  bd.setUint32(17, 0xCAFEF00D, Endian.little);
  Expect.equals(0xCAFEF00D, bd.getUint32(17, Endian.little));
}

void testUint8View() {
  final list = makeList();
  final u8 = list.buffer.asUint8List();
  Expect.equals(64, u8.length);
  Expect.equals(0x44, u8[0]);
  u8[0] = 0x99;
  Expect.equals(0x99, list[0].x & 0xFF);
}

void testInt32x4View() {
  final list = makeList();
  final view = list.buffer.asInt32x4List();
  Expect.equals(4, view.length);
  view[1] = Int32x4(9, 8, 7, 6);
  Expect.equals(9, list[1].x);

  final tail = list.buffer.asInt32x4List(32);
  Expect.equals(2, tail.length);
  Expect.equals(32, tail.offsetInBytes);
  Expect.equals(list[3].y, tail[1].y);
  tail[0] = Int32x4(-5, -6, -7, -8);
  Expect.equals(-6, list[2].y);
}

void testUnmodifiable() {
  final list = makeList();
  final unmodifiable = list.asUnmodifiableView();
  Expect.throws(() => unmodifiable[0] = Int32x4(0, 0, 0, 0));
  final bd = unmodifiable.buffer.asByteData();
  Expect.throws(() => bd.setUint8(0, 1));
  Expect.equals(0x44, bd.getUint8(0));
  final view = unmodifiable.buffer.asInt32x4List();
  Expect.throws(() => view[0] = Int32x4(0, 0, 0, 0));
}

void testFromListAndSetRange() {
  final source = Int32x4List(3);
  source[0] = Int32x4(10, 20, 30, 40);
  source[2] = Int32x4(-1, -2, -3, -4);

  final copy = Int32x4List.fromList(source);
  Expect.equals(3, copy.length);
  Expect.equals(20, copy[0].y);
  Expect.equals(-4, copy[2].w);
  copy[0] = Int32x4(0, 0, 0, 0);
  Expect.equals(20, source[0].y);

  final fromPlain = Int32x4List.fromList([
    Int32x4(5, 6, 7, 8),
    Int32x4(1, 1, 1, 1),
  ]);
  Expect.equals(7, fromPlain[0].z);

  final target = Int32x4List(3);
  target.setRange(1, 3, source, 1);
  Expect.equals(0, target[0].x);
  Expect.equals(source[1].x, target[1].x);
  Expect.equals(-3, target[2].z);

  // Overlapping copy within the same list.
  final overlap = Int32x4List.fromList(source);
  overlap.setRange(1, 3, overlap, 0);
  Expect.equals(10, overlap[1].x);
  Expect.equals(source[1].y, overlap[2].y);
}
