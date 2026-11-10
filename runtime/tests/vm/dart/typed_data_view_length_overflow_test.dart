// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Creating a typed data view that does not fit in its buffer must throw a
// RangeError, also when `length * bytesPerElement` or
// `offsetInBytes + length` does not fit in 64 bits.

// VMOptions=
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import 'dart:typed_data';

import 'package:expect/expect.dart';

void testElementCountOverflow(ByteBuffer buffer, ByteBuffer unmodifiable) {
  // 8-byte elements: 1 << 61 elements are 1 << 64 bytes.
  for (final n in [1 << 61, (1 << 61) + 1, (1 << 61) + 8]) {
    Expect.throwsRangeError(() => Int64List.view(buffer, 0, n));
    Expect.throwsRangeError(() => Uint64List.view(buffer, 0, n));
    Expect.throwsRangeError(() => Float64List.view(buffer, 0, n));
    Expect.throwsRangeError(() => buffer.asInt64List(0, n));
    Expect.throwsRangeError(() => buffer.asUint64List(0, n));
    Expect.throwsRangeError(() => buffer.asFloat64List(0, n));
    Expect.throwsRangeError(() => buffer.asFloat64List(8, n));
    Expect.throwsRangeError(() => unmodifiable.asInt64List(0, n));
  }

  // 16-byte elements: 1 << 60 elements are 1 << 64 bytes.
  for (final n in [1 << 60, (1 << 60) + 1, 3 << 60]) {
    Expect.throwsRangeError(() => Int32x4List.view(buffer, 0, n));
    Expect.throwsRangeError(() => Float32x4List.view(buffer, 0, n));
    Expect.throwsRangeError(() => Float64x2List.view(buffer, 0, n));
    Expect.throwsRangeError(() => buffer.asInt32x4List(0, n));
    Expect.throwsRangeError(() => buffer.asFloat32x4List(0, n));
    Expect.throwsRangeError(() => buffer.asFloat64x2List(0, n));
    Expect.throwsRangeError(() => unmodifiable.asFloat64x2List(0, n));
  }

  // 4-byte elements: 1 << 62 elements are 1 << 64 bytes.
  for (final n in [1 << 61, 1 << 62, (1 << 62) + 1, (1 << 62) + 4]) {
    Expect.throwsRangeError(() => Int32List.view(buffer, 0, n));
    Expect.throwsRangeError(() => Uint32List.view(buffer, 0, n));
    Expect.throwsRangeError(() => Float32List.view(buffer, 0, n));
    Expect.throwsRangeError(() => buffer.asInt32List(0, n));
    Expect.throwsRangeError(() => buffer.asUint32List(0, n));
    Expect.throwsRangeError(() => buffer.asFloat32List(0, n));
    Expect.throwsRangeError(() => unmodifiable.asUint32List(0, n));
  }

  // 2-byte elements: 2 + ((1 << 62) - 1) * 2 is 1 << 63.
  for (final n in [(1 << 62) - 1, 1 << 62, 0x7fffffffffffffff]) {
    Expect.throwsRangeError(() => Int16List.view(buffer, 2, n));
    Expect.throwsRangeError(() => Uint16List.view(buffer, 2, n));
    Expect.throwsRangeError(() => buffer.asInt16List(2, n));
    Expect.throwsRangeError(() => buffer.asUint16List(2, n));
    Expect.throwsRangeError(() => buffer.asInt16List(0, n));
  }
}

void testOffsetPlusLengthOverflow(ByteBuffer buffer, ByteBuffer unmodifiable) {
  // 1 + 0x7fffffffffffffff and (1 << 62) + (1 << 62) are 1 << 63.
  const max = 0x7fffffffffffffff;
  Expect.throwsRangeError(() => ByteData.view(buffer, 1, max));
  Expect.throwsRangeError(() => buffer.asByteData(1, max));
  Expect.throwsRangeError(() => unmodifiable.asByteData(1, max));
  Expect.throwsRangeError(() => Uint8List.view(buffer, 1, max));
  Expect.throwsRangeError(() => buffer.asUint8List(1, max));
  Expect.throwsRangeError(() => buffer.asInt8List(1, max));
  Expect.throwsRangeError(() => buffer.asUint8ClampedList(1, max));
  const big = 1 << 62;
  Expect.throwsRangeError(() => ByteData.view(buffer, big, big));
  Expect.throwsRangeError(() => buffer.asByteData(big, big));
  Expect.throwsRangeError(() => Uint8List.view(buffer, big, big));
}

void testNegativeLength(ByteBuffer buffer) {
  // Negative element counts whose size in bytes wraps to a small positive
  // value.
  Expect.throwsRangeError(() => buffer.asInt64List(0, -(1 << 61) + 1));
  Expect.throwsRangeError(() => Float64List.view(buffer, 0, -(1 << 61) + 1));
  Expect.throwsRangeError(() => buffer.asInt32List(0, -(1 << 62) + 1));
  Expect.throwsRangeError(() => Uint32List.view(buffer, 0, -(1 << 62) + 1));
  Expect.throwsRangeError(() => buffer.asFloat64x2List(0, -(1 << 60) + 1));
  Expect.throwsRangeError(() => Int32x4List.view(buffer, 0, -(1 << 60) + 1));
  Expect.throwsRangeError(() => buffer.asUint8List(0, -1));
  Expect.throwsRangeError(() => buffer.asByteData(0, -1));
}

void testBounds(ByteBuffer buffer) {
  // An offset past the end of the buffer throws, also for an empty view.
  Expect.throwsRangeError(() => buffer.asByteData(65, 0));
  Expect.throwsRangeError(() => buffer.asInt64List(72, 0));
  Expect.throwsRangeError(() => buffer.asFloat64x2List(72));

  // Views up to the end of the buffer still work.
  Expect.equals(8, Int64List.view(buffer).length);
  Expect.equals(1, buffer.asInt64List(56, 1).length);
  Expect.throwsRangeError(() => buffer.asInt64List(56, 2));
  Expect.equals(0, buffer.asInt64List(64, 0).length);
  Expect.equals(0, buffer.asInt64List(64).length);
  Expect.equals(4, Float64x2List.view(buffer).length);
  Expect.equals(3, buffer.asFloat64x2List(16).length);
  Expect.throwsRangeError(() => buffer.asFloat64x2List(16, 4));
  Expect.equals(16, buffer.asUint16List(32).length);
  Expect.equals(31, buffer.asInt16List(2).length);
  Expect.equals(64, ByteData.view(buffer).lengthInBytes);
  Expect.equals(0, ByteData.view(buffer, 64).lengthInBytes);
  Expect.equals(1, buffer.asUint8List(63, 1).length);
  Expect.throwsRangeError(() => buffer.asUint8List(63, 2));
}

void main() {
  final buffer = Uint8List(64).buffer;
  final unmodifiable = buffer.asUint8List().asUnmodifiableView().buffer;
  for (var i = 0; i < 20; i++) {
    testElementCountOverflow(buffer, unmodifiable);
    testOffsetPlusLengthOverflow(buffer, unmodifiable);
    testNegativeLength(buffer);
    testBounds(buffer);
  }
}
