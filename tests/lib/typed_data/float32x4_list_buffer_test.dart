// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the buffer of a Float32x4List created through its constructors,
// including byte level access and views sharing the storage.

import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  testLengths();
  testByteDataReads();
  testByteDataWrites();
  testUint8View();
  testFloat32x4View();
  testUnmodifiable();
  testFromListAndSetRange();
}

Float32x4List makeList() {
  final list = Float32x4List(4);
  list[0] = Float32x4(1.5, -2.25, 3.75, 0.0);
  list[3] = Float32x4(100.0, 200.0, 300.0, 400.0);
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
  // Element 0 lanes are at byte offsets 0, 4, 8, 12.
  Expect.equals(1.5, bd.getFloat32(0, Endian.little));
  Expect.equals(-2.25, bd.getFloat32(4, Endian.little));
  Expect.equals(3.75, bd.getFloat32(8, Endian.little));
  Expect.equals(0.0, bd.getFloat32(12, Endian.little));
  // Element 3 starts at byte 48.
  Expect.equals(100.0, bd.getFloat32(48, Endian.little));
  Expect.equals(400.0, bd.getFloat32(60, Endian.little));
  // The raw f32 bits are also visible as integers (1.5 == 0x3FC00000).
  Expect.equals(0x3FC00000, bd.getUint32(0, Endian.little));
}

void testByteDataWrites() {
  final list = makeList();
  final bd = list.buffer.asByteData();
  bd.setFloat32(12, 9.5, Endian.little);
  Expect.equals(9.5, list[0].w);
  bd.setFloat32(48, -1.25, Endian.little);
  Expect.equals(-1.25, list[3].x);
  // Byte-granular write of the f32 bit pattern for 1.0 into element 1 lane x.
  bd.setUint32(16, 0x3F800000, Endian.little);
  Expect.equals(1.0, list[1].x);
}

void testUint8View() {
  final list = makeList();
  final u8 = list.buffer.asUint8List();
  Expect.equals(64, u8.length);
  // 1.5 == 0x3FC00000, little-endian byte 3 is 0x3F.
  Expect.equals(0x3F, u8[3]);
  u8[0] = 0xAB;
  Expect.equals(0xAB, list.buffer.asByteData().getUint8(0));
}

void testFloat32x4View() {
  final list = makeList();
  final view = list.buffer.asFloat32x4List();
  Expect.equals(4, view.length);
  view[1] = Float32x4(9.0, 8.0, 7.0, 6.0);
  Expect.equals(9.0, list[1].x);

  final tail = list.buffer.asFloat32x4List(32);
  Expect.equals(2, tail.length);
  Expect.equals(32, tail.offsetInBytes);
  Expect.equals(list[3].y, tail[1].y);
  tail[0] = Float32x4(-5.0, -6.0, -7.0, -8.0);
  Expect.equals(-6.0, list[2].y);
}

void testUnmodifiable() {
  final list = makeList();
  final unmodifiable = list.asUnmodifiableView();
  Expect.throws(() => unmodifiable[0] = Float32x4(0.0, 0.0, 0.0, 0.0));
  final bd = unmodifiable.buffer.asByteData();
  Expect.throws(() => bd.setFloat32(0, 1.0));
  Expect.equals(1.5, bd.getFloat32(0, Endian.little));
  final view = unmodifiable.buffer.asFloat32x4List();
  Expect.throws(() => view[0] = Float32x4(0.0, 0.0, 0.0, 0.0));
}

void testFromListAndSetRange() {
  final source = Float32x4List(3);
  source[0] = Float32x4(10.0, 20.0, 30.0, 40.0);
  source[2] = Float32x4(-1.0, -2.0, -3.0, -4.0);

  final copy = Float32x4List.fromList(source);
  Expect.equals(3, copy.length);
  Expect.equals(20.0, copy[0].y);
  Expect.equals(-4.0, copy[2].w);
  copy[0] = Float32x4(0.0, 0.0, 0.0, 0.0);
  Expect.equals(20.0, source[0].y);

  final fromPlain = Float32x4List.fromList([
    Float32x4(5.0, 6.0, 7.0, 8.0),
    Float32x4(1.0, 1.0, 1.0, 1.0),
  ]);
  Expect.equals(7.0, fromPlain[0].z);

  final target = Float32x4List(3);
  target.setRange(1, 3, source, 1);
  Expect.equals(0.0, target[0].x);
  Expect.equals(source[1].x, target[1].x);
  Expect.equals(-3.0, target[2].z);

  // Overlapping copy within the same list.
  final overlap = Float32x4List.fromList(source);
  overlap.setRange(1, 3, overlap, 0);
  Expect.equals(10.0, overlap[1].x);
  Expect.equals(source[1].y, overlap[2].y);
}
