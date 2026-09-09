// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the buffer of a Float64x2List created through its constructors,
// including byte level access and views sharing the storage.

import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  testLengths();
  testByteDataReads();
  testByteDataWrites();
  testUint8View();
  testFloat64x2View();
  testUnmodifiable();
  testFromListAndSetRange();
}

Float64x2List makeList() {
  final list = Float64x2List(4);
  list[0] = Float64x2(1.5, -2.25);
  list[3] = Float64x2(100.0, 400.0);
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
  // Element 0 lanes are at byte offsets 0 and 8.
  Expect.equals(1.5, bd.getFloat64(0, Endian.little));
  Expect.equals(-2.25, bd.getFloat64(8, Endian.little));
  // Element 3 starts at byte 48.
  Expect.equals(100.0, bd.getFloat64(48, Endian.little));
  Expect.equals(400.0, bd.getFloat64(56, Endian.little));
  // The raw f64 bits are also visible (1.5 == 0x3FF8000000000000). Uint64
  // accessors are unsupported on the web, so check the two 32-bit halves.
  Expect.equals(0x00000000, bd.getUint32(0, Endian.little));
  Expect.equals(0x3FF80000, bd.getUint32(4, Endian.little));
}

void testByteDataWrites() {
  final list = makeList();
  final bd = list.buffer.asByteData();
  bd.setFloat64(8, 9.5, Endian.little);
  Expect.equals(9.5, list[0].y);
  bd.setFloat64(48, -1.25, Endian.little);
  Expect.equals(-1.25, list[3].x);
  // Byte-granular write of the f64 bit pattern for 1.0 into element 1 lane x.
  // Uint64 accessors are unsupported on the web, so write the two 32-bit
  // halves.
  bd.setUint32(16, 0x00000000, Endian.little);
  bd.setUint32(20, 0x3FF00000, Endian.little);
  Expect.equals(1.0, list[1].x);
}

void testUint8View() {
  final list = makeList();
  final u8 = list.buffer.asUint8List();
  Expect.equals(64, u8.length);
  // 1.5 == 0x3FF8000000000000, little-endian byte 7 is 0x3F.
  Expect.equals(0x3F, u8[7]);
  u8[0] = 0xAB;
  Expect.equals(0xAB, list.buffer.asByteData().getUint8(0));
}

void testFloat64x2View() {
  final list = makeList();
  final view = list.buffer.asFloat64x2List();
  Expect.equals(4, view.length);
  view[1] = Float64x2(9.0, 8.0);
  Expect.equals(9.0, list[1].x);

  final tail = list.buffer.asFloat64x2List(32);
  Expect.equals(2, tail.length);
  Expect.equals(32, tail.offsetInBytes);
  Expect.equals(list[3].y, tail[1].y);
  tail[0] = Float64x2(-5.0, -6.0);
  Expect.equals(-6.0, list[2].y);
}

void testUnmodifiable() {
  final list = makeList();
  final unmodifiable = list.asUnmodifiableView();
  Expect.throws(() => unmodifiable[0] = Float64x2(0.0, 0.0));
  final bd = unmodifiable.buffer.asByteData();
  Expect.throws(() => bd.setFloat64(0, 1.0));
  Expect.equals(1.5, bd.getFloat64(0, Endian.little));
  final view = unmodifiable.buffer.asFloat64x2List();
  Expect.throws(() => view[0] = Float64x2(0.0, 0.0));
}

void testFromListAndSetRange() {
  final source = Float64x2List(3);
  source[0] = Float64x2(10.0, 20.0);
  source[2] = Float64x2(-1.0, -2.0);

  final copy = Float64x2List.fromList(source);
  Expect.equals(3, copy.length);
  Expect.equals(20.0, copy[0].y);
  Expect.equals(-2.0, copy[2].y);
  copy[0] = Float64x2(0.0, 0.0);
  Expect.equals(20.0, source[0].y);

  final fromPlain = Float64x2List.fromList([
    Float64x2(5.0, 6.0),
    Float64x2(1.0, 1.0),
  ]);
  Expect.equals(6.0, fromPlain[0].y);

  final target = Float64x2List(3);
  target.setRange(1, 3, source, 1);
  Expect.equals(0.0, target[0].x);
  Expect.equals(source[1].x, target[1].x);
  Expect.equals(-2.0, target[2].y);

  // Overlapping copy within the same list.
  final overlap = Float64x2List.fromList(source);
  overlap.setRange(1, 3, overlap, 0);
  Expect.equals(10.0, overlap[1].x);
  Expect.equals(source[1].y, overlap[2].y);
}
