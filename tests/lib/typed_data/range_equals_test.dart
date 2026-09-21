// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:expect/variations.dart' show jsNumbers;

final bool supportsInt64 = !jsNumbers;

void testRangeEquals<T extends TypedData>({
  required String typeName,
  required T Function(List<int>) createList,
  required T Function(T list, int offset, int length) createView,
  required bool Function(T a, int start, int end, T b, [int otherStart])
  callRangeEquals,
  required int Function(T) getLength,
  required List<int> sampleData1,
  required List<int> sampleData2,
}) {
  final a = createList(sampleData1);
  final b = createList(sampleData1);
  final c = createList(sampleData2);
  final len = getLength(a);

  // Full comparison: identical content
  Expect.isTrue(
    callRangeEquals(a, 0, len, b, 0),
    '$typeName: full comparison identical content',
  );

  // Full comparison using default otherStart = 0
  Expect.isTrue(
    callRangeEquals(a, 0, len, b),
    '$typeName: full comparison default otherStart = 0',
  );

  // Full comparison: different content
  Expect.isFalse(
    callRangeEquals(a, 0, len, c, 0),
    '$typeName: full comparison different content',
  );

  // Identical instance
  Expect.isTrue(
    callRangeEquals(a, 0, len, a, 0),
    '$typeName: identical instance',
  );
  if (len >= 4) {
    Expect.isTrue(
      callRangeEquals(a, 2, 4, a, 2),
      '$typeName: identical instance with non-zero start',
    );
  }

  // Unmodifiable views
  final unmodA = (a as dynamic).asUnmodifiableView() as T;
  final unmodB = (b as dynamic).asUnmodifiableView() as T;
  final unmodC = (c as dynamic).asUnmodifiableView() as T;
  Expect.isTrue(
    callRangeEquals(unmodA, 0, len, unmodB, 0),
    '$typeName: unmodifiable views matching',
  );
  Expect.isTrue(
    callRangeEquals(unmodA, 0, len, b, 0),
    '$typeName: unmodifiable view matching mutable list',
  );
  Expect.isTrue(
    callRangeEquals(a, 0, len, unmodB, 0),
    '$typeName: mutable list matching unmodifiable view',
  );
  Expect.isFalse(
    callRangeEquals(unmodA, 0, len, unmodC, 0),
    '$typeName: unmodifiable views mismatching',
  );

  // Empty ranges (start == end) always return true
  Expect.isTrue(
    callRangeEquals(a, 0, 0, b, 0),
    '$typeName: empty range at start',
  );
  Expect.isTrue(
    callRangeEquals(a, len, len, b, 0),
    '$typeName: empty range at end',
  );
  Expect.isTrue(
    callRangeEquals(a, len, len, b, len),
    '$typeName: empty range at end of both',
  );
  Expect.isTrue(
    callRangeEquals(a, 2, 2, c, 5),
    '$typeName: empty range on different content',
  );

  // Subrange matching
  if (len >= 8) {
    // Compare slice [2, 6)
    Expect.isTrue(
      callRangeEquals(a, 2, 6, b, 2),
      '$typeName: subrange [2, 6) matching',
    );

    // Differences before start and after end must be ignored
    final diffList = List<int>.from(sampleData1);
    diffList[0] = sampleData2[0]; // before start (start = 2)
    diffList[len - 1] = sampleData2[len - 1]; // after end (end = 6)
    final diffOutside = createList(diffList);
    Expect.isTrue(
      callRangeEquals(a, 2, 6, diffOutside, 2),
      '$typeName: differences before start and after end must be ignored',
    );

    // Mismatch at start of subrange
    final mStart = createList(
      List<int>.from(sampleData1)..[2] = sampleData2[2],
    );
    Expect.isFalse(
      callRangeEquals(a, 2, 6, mStart, 2),
      '$typeName: mismatch at start of subrange',
    );

    // Mismatch in middle of subrange
    final mMid = createList(List<int>.from(sampleData1)..[4] = sampleData2[4]);
    Expect.isFalse(
      callRangeEquals(a, 2, 6, mMid, 2),
      '$typeName: mismatch in middle of subrange',
    );

    // Mismatch at end of subrange (index 5)
    final mEnd = createList(List<int>.from(sampleData1)..[5] = sampleData2[5]);
    Expect.isFalse(
      callRangeEquals(a, 2, 6, mEnd, 2),
      '$typeName: mismatch at end of subrange',
    );

    // Matching subrange at different offsets:
    // Put sampleData1[2..6] at index 3 in another list
    final shifted = List<int>.filled(len + 2, 0);
    for (int i = 0; i < 4; i++) {
      shifted[3 + i] = sampleData1[2 + i];
    }
    final shiftedList = createList(shifted);
    Expect.isTrue(
      callRangeEquals(a, 2, 6, shiftedList, 3),
      '$typeName: matching subrange with shifted offset',
    );
    Expect.isFalse(
      callRangeEquals(a, 2, 6, shiftedList, 2),
      '$typeName: mismatching subrange with wrong offset',
    );

    // Overlapping subranges within the same buffer
    final periodic = List<int>.generate(len, (i) => sampleData1[i % 2]);
    final periodicList = createList(periodic);
    Expect.isTrue(
      callRangeEquals(periodicList, 0, 4, periodicList, 2),
      '$typeName: overlapping matching subranges on identical instance',
    );
    Expect.isFalse(
      callRangeEquals(periodicList, 0, 4, periodicList, 1),
      '$typeName: overlapping mismatching subranges on identical instance',
    );
  }

  // Views with non-zero byte offset
  if (len >= 8) {
    final viewA = createView(a, 2, 4);
    final viewB = createView(b, 2, 4);
    Expect.isTrue(
      callRangeEquals(viewA, 0, 4, viewB, 0),
      '$typeName: views matching',
    );
    Expect.isTrue(
      callRangeEquals(viewA, 1, 3, viewB, 1),
      '$typeName: subview matching',
    );
  }

  // Error cases: RangeError
  // start < 0
  Expect.throwsRangeError(
    () => callRangeEquals(a, -1, len, b, 0),
    '$typeName: start < 0',
  );
  // end < start
  Expect.throwsRangeError(
    () => callRangeEquals(a, 3, 2, b, 0),
    '$typeName: end < start',
  );
  // end > length
  Expect.throwsRangeError(
    () => callRangeEquals(a, 0, len + 1, b, 0),
    '$typeName: end > length',
  );
  // otherStart < 0
  Expect.throwsRangeError(
    () => callRangeEquals(a, 0, 1, b, -1),
    '$typeName: otherStart < 0',
  );
  // otherStart + count > other.length
  Expect.throwsRangeError(
    () => callRangeEquals(a, 0, 2, b, len - 1),
    '$typeName: otherStart + count > other.length',
  );
  // otherStart > other.length on empty range
  Expect.throwsRangeError(
    () => callRangeEquals(a, 0, 0, b, len + 1),
    '$typeName: otherStart > other.length on empty range',
  );
}

void testUint8List() {
  testRangeEquals<Uint8List>(
    typeName: 'Uint8List',
    createList: (l) => Uint8List.fromList(l),
    createView: (l, offset, len) =>
        Uint8List.view(l.buffer, l.offsetInBytes + offset, len),
    callRangeEquals: (a, start, end, b, [otherStart = 0]) =>
        a.rangeEquals(start, end, b, otherStart),
    getLength: (l) => l.length,
    sampleData1: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
    sampleData2: [
      101,
      102,
      103,
      104,
      105,
      106,
      107,
      108,
      109,
      110,
      111,
      112,
      113,
      114,
      115,
      116,
    ],
  );
}

void testInt8List() {
  testRangeEquals<Int8List>(
    typeName: 'Int8List',
    createList: (l) => Int8List.fromList(l),
    createView: (l, offset, len) =>
        Int8List.view(l.buffer, l.offsetInBytes + offset, len),
    callRangeEquals: (a, start, end, b, [otherStart = 0]) =>
        a.rangeEquals(start, end, b, otherStart),
    getLength: (l) => l.length,
    sampleData1: [-128, -50, 0, 1, 2, 3, 4, 5, 50, 127, -1, -2, -3, -4, -5, 10],
    sampleData2: [
      -1,
      -2,
      -3,
      -4,
      -5,
      -6,
      -7,
      -8,
      -9,
      -10,
      -50,
      -100,
      -128,
      0,
      50,
      100,
    ],
  );
}

void testUint8ClampedList() {
  testRangeEquals<Uint8ClampedList>(
    typeName: 'Uint8ClampedList',
    createList: (l) => Uint8ClampedList.fromList(l),
    createView: (l, offset, len) =>
        Uint8ClampedList.view(l.buffer, l.offsetInBytes + offset, len),
    callRangeEquals: (a, start, end, b, [otherStart = 0]) =>
        a.rangeEquals(start, end, b, otherStart),
    getLength: (l) => l.length,
    sampleData1: [
      0,
      1,
      2,
      50,
      100,
      150,
      200,
      255,
      10,
      20,
      30,
      40,
      50,
      60,
      70,
      80,
    ],
    sampleData2: [
      255,
      254,
      253,
      200,
      150,
      100,
      50,
      0,
      80,
      70,
      60,
      50,
      40,
      30,
      20,
      10,
    ],
  );
}

void testUint16List() {
  testRangeEquals<Uint16List>(
    typeName: 'Uint16List',
    createList: (l) => Uint16List.fromList(l),
    createView: (l, offset, len) =>
        Uint16List.view(l.buffer, l.offsetInBytes + offset * 2, len),
    callRangeEquals: (a, start, end, b, [otherStart = 0]) =>
        a.rangeEquals(start, end, b, otherStart),
    getLength: (l) => l.length,
    sampleData1: [
      1000,
      2000,
      3000,
      4000,
      5000,
      6000,
      7000,
      8000,
      9000,
      10000,
      65535,
      0,
      1,
      2,
      3,
      4,
    ],
    sampleData2: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
  );
}

void testInt16List() {
  testRangeEquals<Int16List>(
    typeName: 'Int16List',
    createList: (l) => Int16List.fromList(l),
    createView: (l, offset, len) =>
        Int16List.view(l.buffer, l.offsetInBytes + offset * 2, len),
    callRangeEquals: (a, start, end, b, [otherStart = 0]) =>
        a.rangeEquals(start, end, b, otherStart),
    getLength: (l) => l.length,
    sampleData1: [
      -32768,
      -1000,
      0,
      1000,
      32767,
      -1,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
    ],
    sampleData2: [
      -1000,
      -2000,
      -3000,
      -32768,
      -1,
      0,
      1000,
      2000,
      3000,
      32767,
      -5,
      -6,
      -7,
      -8,
      -9,
      -10,
    ],
  );
}

void testUint32List() {
  testRangeEquals<Uint32List>(
    typeName: 'Uint32List',
    createList: (l) => Uint32List.fromList(l),
    createView: (l, offset, len) =>
        Uint32List.view(l.buffer, l.offsetInBytes + offset * 4, len),
    callRangeEquals: (a, start, end, b, [otherStart = 0]) =>
        a.rangeEquals(start, end, b, otherStart),
    getLength: (l) => l.length,
    sampleData1: [
      0x12345678,
      0x7abcdef0,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      0x7fffffff,
      100,
      200,
      300,
    ],
    sampleData2: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
  );
}

void testInt32List() {
  testRangeEquals<Int32List>(
    typeName: 'Int32List',
    createList: (l) => Int32List.fromList(l),
    createView: (l, offset, len) =>
        Int32List.view(l.buffer, l.offsetInBytes + offset * 4, len),
    callRangeEquals: (a, start, end, b, [otherStart = 0]) =>
        a.rangeEquals(start, end, b, otherStart),
    getLength: (l) => l.length,
    sampleData1: [
      -2147483648,
      2147483647,
      -1,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
    ],
    sampleData2: [
      -100,
      -200,
      -300,
      -2147483648,
      -1,
      0,
      100,
      200,
      300,
      2147483647,
      -5,
      -6,
      -7,
      -8,
      -9,
      -10,
    ],
  );
}

void testUint64List() {
  int u64(int high, int low) => (high << 32) | low;
  testRangeEquals<Uint64List>(
    typeName: 'Uint64List',
    createList: (l) => Uint64List.fromList(l),
    createView: (l, offset, len) =>
        Uint64List.view(l.buffer, l.offsetInBytes + offset * 8, len),
    callRangeEquals: (a, start, end, b, [otherStart = 0]) =>
        a.rangeEquals(start, end, b, otherStart),
    getLength: (l) => l.length,
    sampleData1: [
      u64(0x12345678, 0x9ABCDEF0),
      u64(0x00000001, 0x00000000),
      u64(0x00000000, 0x00000001),
      u64(0x7FFFFFFF, 0xFFFFFFFF),
      u64(0xFFFFFFFF, 0xFFFFFFFF),
      u64(0x01020304, 0x05060708),
      u64(0x10203040, 0x50607080),
      u64(0x00000000, 0xFFFFFFFF),
      u64(0xFFFFFFFF, 0x00000000),
      u64(0xAAAAAAAA, 0xAAAAAAAA),
      u64(0x55555555, 0x55555555),
      u64(0x00FF00FF, 0x00FF00FF),
      u64(0xFF00FF00, 0xFF00FF00),
      u64(0x0F0F0F0F, 0x0F0F0F0F),
      u64(0xF0F0F0F0, 0xF0F0F0F0),
      u64(0xDEADBEEF, 0xCAFEBABE),
    ],
    sampleData2: [
      u64(0x12345678, 0x9ABCDEF1),
      u64(0x00000002, 0x00000000),
      u64(0x00000000, 0x00000002),
      u64(0x7FFFFFFF, 0xFFFFFFFE),
      u64(0xFFFFFFFF, 0xFFFFFFFE),
      u64(0x01020304, 0x05060709),
      u64(0x10203040, 0x50607081),
      u64(0x00000000, 0xFFFFFFFE),
      u64(0xFFFFFFFF, 0x00000001),
      u64(0xAAAAAAAA, 0xAAAAAAAB),
      u64(0x55555555, 0x55555554),
      u64(0x00FF00FF, 0x00FF00FE),
      u64(0xFF00FF00, 0xFF00FF01),
      u64(0x0F0F0F0F, 0x0F0F0F0E),
      u64(0xF0F0F0F0, 0xF0F0F0F1),
      u64(0xDEADBEEF, 0xCAFEBABF),
    ],
  );
}

void testInt64List() {
  int i64(int high, int low) => (high << 32) | low;
  testRangeEquals<Int64List>(
    typeName: 'Int64List',
    createList: (l) => Int64List.fromList(l),
    createView: (l, offset, len) =>
        Int64List.view(l.buffer, l.offsetInBytes + offset * 8, len),
    callRangeEquals: (a, start, end, b, [otherStart = 0]) =>
        a.rangeEquals(start, end, b, otherStart),
    getLength: (l) => l.length,
    sampleData1: [
      i64(0x80000000, 0x00000000),
      i64(0x7FFFFFFF, 0xFFFFFFFF),
      i64(0x80000000, 0x00000001),
      -1,
      0,
      1,
      i64(-1, 0x00000000),
      i64(1, 0x00000000),
      -100,
      100,
      i64(0x12345678, 0x9ABCDEF0),
      i64(-0x12345678, 0x9ABCDEF0),
      i64(0x55555555, 0x55555555),
      i64(-0x55555555, 0x55555555),
      i64(0x0F0F0F0F, 0x0F0F0F0F),
      i64(-0x0F0F0F0F, 0x0F0F0F0F),
    ],
    sampleData2: [
      i64(0x80000000, 0x00000001),
      i64(0x7FFFFFFF, 0xFFFFFFFE),
      i64(0x80000000, 0x00000002),
      -2,
      1,
      2,
      i64(-2, 0x00000000),
      i64(2, 0x00000000),
      -101,
      101,
      i64(0x12345678, 0x9ABCDEF1),
      i64(-0x12345678, 0x9ABCDEF1),
      i64(0x55555555, 0x55555554),
      i64(-0x55555555, 0x55555554),
      i64(0x0F0F0F0F, 0x0F0F0F0E),
      i64(-0x0F0F0F0F, 0x0F0F0F0E),
    ],
  );
}

void testByteData() {
  ByteData createBD(List<int> bytes) {
    final bd = ByteData(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      bd.setUint8(i, bytes[i]);
    }
    return bd;
  }

  testRangeEquals<ByteData>(
    typeName: 'ByteData',
    createList: createBD,
    createView: (bd, offset, len) =>
        ByteData.view(bd.buffer, bd.offsetInBytes + offset, len),
    callRangeEquals: (a, start, end, b, [otherStart = 0]) =>
        a.rangeEquals(start, end, b, otherStart),
    getLength: (bd) => bd.lengthInBytes,
    sampleData1: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
    sampleData2: [
      10,
      20,
      30,
      40,
      50,
      60,
      70,
      80,
      90,
      100,
      110,
      120,
      130,
      140,
      150,
      160,
    ],
  );
}

void testByteDataChunking() {
  for (final count in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 15, 16, 17, 31, 32, 33]) {
    final a = ByteData(count + 8);
    final b = ByteData(count + 8);
    for (int i = 0; i < count + 8; i++) {
      a.setUint8(i, (i * 17 + 1) & 0xFF);
      b.setUint8(i, (i * 17 + 1) & 0xFF);
    }
    // Matching range
    Expect.isTrue(
      a.rangeEquals(2, 2 + count, b, 2),
      'ByteData matching range for count $count',
    );

    // Unaligned offsets
    final aUnaligned = ByteData(count + 5);
    final bUnaligned = ByteData(count + 5);
    for (int i = 0; i < count + 5; i++) {
      aUnaligned.setUint8(i, 42);
      bUnaligned.setUint8(i, 42);
    }
    Expect.isTrue(
      aUnaligned.rangeEquals(1, 1 + count, bUnaligned, 3),
      'ByteData unaligned matching range for count $count',
    );

    // Mismatch at each position in the range (testing 32-bit chunk & scalar remainder loops)
    for (int mismatchPos = 0; mismatchPos < count; mismatchPos++) {
      final modified = ByteData(count + 8);
      for (int i = 0; i < count + 8; i++) {
        modified.setUint8(i, a.getUint8(i));
      }
      modified.setUint8(2 + mismatchPos, a.getUint8(2 + mismatchPos) ^ 0xFF);
      Expect.isFalse(
        a.rangeEquals(2, 2 + count, modified, 2),
        'ByteData mismatch at pos $mismatchPos for count $count',
      );
    }
  }
}

void testEmptyBuffers() {
  void testEmpty<T extends TypedData>(
    String typeName,
    T Function(int) create,
    bool Function(T a, int start, int end, T b, [int otherStart]) call,
  ) {
    final e1 = create(0);
    final e2 = create(0);
    final nonE = create(5);

    Expect.isTrue(
      call(e1, 0, 0, e2, 0),
      '$typeName: empty buffers equal with offset 0',
    );
    Expect.isTrue(
      call(e1, 0, 0, e2),
      '$typeName: empty buffers equal with default offset',
    );
    Expect.isTrue(
      call(e1, 0, 0, nonE, 0),
      '$typeName: empty buffer equals start of non-empty',
    );
    Expect.isTrue(
      call(nonE, 0, 0, e1, 0),
      '$typeName: start of non-empty equals empty buffer',
    );
    Expect.isTrue(
      call(e1, 0, 0, nonE, 5),
      '$typeName: empty buffer equals end of non-empty',
    );

    Expect.throwsRangeError(
      () => call(e1, 0, 1, e2, 0),
      '$typeName: count > length on empty buffer',
    );
    Expect.throwsRangeError(
      () => call(e1, 0, 0, e2, 1),
      '$typeName: otherStart > other.length on empty buffer',
    );
    Expect.throwsRangeError(
      () => call(e1, 1, 1, e2, 0),
      '$typeName: start > length on empty buffer',
    );
    Expect.throwsRangeError(
      () => call(e1, -1, -1, e2, 0),
      '$typeName: negative start on empty buffer',
    );
    Expect.throwsRangeError(
      () => call(nonE, 0, 0, nonE, -1),
      '$typeName: negative otherStart on empty range',
    );
    Expect.throwsRangeError(
      () => call(nonE, 0, 0, nonE, 6),
      '$typeName: otherStart > length on empty range',
    );
  }

  testEmpty<Uint8List>(
    'Uint8List',
    Uint8List.new,
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  testEmpty<Int8List>(
    'Int8List',
    Int8List.new,
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  testEmpty<Uint8ClampedList>(
    'Uint8ClampedList',
    Uint8ClampedList.new,
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  testEmpty<Uint16List>(
    'Uint16List',
    Uint16List.new,
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  testEmpty<Int16List>(
    'Int16List',
    Int16List.new,
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  testEmpty<Uint32List>(
    'Uint32List',
    Uint32List.new,
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  testEmpty<Int32List>(
    'Int32List',
    Int32List.new,
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  if (supportsInt64) {
    testEmpty<Uint64List>(
      'Uint64List',
      Uint64List.new,
      (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
    );
    testEmpty<Int64List>(
      'Int64List',
      Int64List.new,
      (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
    );
  }
  testEmpty<ByteData>(
    'ByteData',
    ByteData.new,
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
}

void testCrossViews() {
  final u32 = Uint32List(4);
  for (int i = 0; i < 4; i++) {
    u32[i] = 0x01020304;
  }
  final u8View = u32.buffer.asUint8List();
  final u8Native = Uint8List.fromList(u8View);

  Expect.isTrue(
    u8View.rangeEquals(0, 16, u8Native, 0),
    'u8View rangeEquals u8Native',
  );
  Expect.isTrue(
    u8Native.rangeEquals(0, 16, u8View, 0),
    'u8Native rangeEquals u8View',
  );
  Expect.isTrue(
    u8View.rangeEquals(2, 10, u8Native, 2),
    'u8View subrange rangeEquals u8Native subrange',
  );
  Expect.isTrue(
    u8Native.rangeEquals(2, 10, u8View, 2),
    'u8Native subrange rangeEquals u8View subrange',
  );

  final u8Diff = Uint8List.fromList(u8Native)..[5] ^= 0xFF;
  Expect.isFalse(
    u8View.rangeEquals(0, 16, u8Diff, 0),
    'u8View mismatching u8Diff',
  );
  Expect.isFalse(
    u8Diff.rangeEquals(0, 16, u8View, 0),
    'u8Diff mismatching u8View',
  );
}

void testSublistView() {
  final base = Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80]);
  final sub1 = Uint8List.sublistView(base, 2, 6); // [30, 40, 50, 60], len 4
  final sub2 = Uint8List.fromList([30, 40, 50, 60]);
  Expect.isTrue(
    sub1.rangeEquals(0, 4, sub2, 0),
    'sublistView equals matching list',
  );
  Expect.isTrue(
    sub2.rangeEquals(0, 4, sub1, 0),
    'list equals matching sublistView',
  );
  Expect.isTrue(
    sub1.rangeEquals(1, 3, base, 3),
    'subrange of sublistView matches base slice',
  );

  final base32 = Int32List.fromList([100, 200, 300, 400, 500, 600]);
  final sub32_1 = Int32List.sublistView(base32, 1, 4); // [200, 300, 400], len 3
  final sub32_2 = Int32List.fromList([200, 300, 400]);
  Expect.isTrue(
    sub32_1.rangeEquals(0, 3, sub32_2, 0),
    'sublistView Int32 equals matching list',
  );
  Expect.isTrue(
    sub32_2.rangeEquals(0, 3, sub32_1, 0),
    'list Int32 equals matching sublistView',
  );
}

void testViewsWithSurroundingGarbage() {
  // Verify that typed data views with offsetInBytes > 0 properly compare
  // elements from their offset and do not read from offset 0 of the buffer.
  for (final elementSize in [1, 2, 4, 8]) {
    if (elementSize == 8 && !supportsInt64) continue;

    final bufferBytes = 64;
    final viewOffsetElements = 2;
    final viewLengthElements = 4;
    final viewOffsetBytes = viewOffsetElements * elementSize;

    // Buffer 1: filled with 0xAA surrounding the view window
    final buf1 = Uint8List(bufferBytes)..fillRange(0, bufferBytes, 0xAA);
    // Buffer 2: filled with 0x55 surrounding the view window
    final buf2 = Uint8List(bufferBytes)..fillRange(0, bufferBytes, 0x55);
    // Buffer 3: filled with 0xAA surrounding the view window, but different data inside
    final buf3 = Uint8List(bufferBytes)..fillRange(0, bufferBytes, 0xAA);

    // Populate identical test values in the view window of buf1 and buf2
    for (int i = 0; i < viewLengthElements * elementSize; i++) {
      buf1[viewOffsetBytes + i] = (i + 1) & 0xFF;
      buf2[viewOffsetBytes + i] = (i + 1) & 0xFF;
      buf3[viewOffsetBytes + i] = (i + 0x80) & 0xFF;
    }

    if (elementSize == 1) {
      final v1 = Uint8List.view(
        buf1.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      final v2 = Uint8List.view(
        buf2.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      final v3 = Uint8List.view(
        buf3.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      Expect.isTrue(v1.rangeEquals(0, viewLengthElements, v2));
      Expect.isFalse(v1.rangeEquals(0, viewLengthElements, v3));
      Expect.isTrue(v1.rangeEquals(1, 3, v2, 1));
      Expect.isFalse(v1.rangeEquals(1, 3, v3, 1));

      final bd1 = ByteData.view(
        buf1.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      final bd2 = ByteData.view(
        buf2.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      final bd3 = ByteData.view(
        buf3.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      Expect.isTrue(bd1.rangeEquals(0, viewLengthElements, bd2));
      Expect.isFalse(bd1.rangeEquals(0, viewLengthElements, bd3));
    } else if (elementSize == 2) {
      final v1 = Uint16List.view(
        buf1.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      final v2 = Uint16List.view(
        buf2.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      final v3 = Uint16List.view(
        buf3.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      Expect.isTrue(v1.rangeEquals(0, viewLengthElements, v2));
      Expect.isFalse(v1.rangeEquals(0, viewLengthElements, v3));
    } else if (elementSize == 4) {
      final v1 = Int32List.view(
        buf1.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      final v2 = Int32List.view(
        buf2.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      final v3 = Int32List.view(
        buf3.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      Expect.isTrue(v1.rangeEquals(0, viewLengthElements, v2));
      Expect.isFalse(v1.rangeEquals(0, viewLengthElements, v3));
    } else if (elementSize == 8) {
      final v1 = Uint64List.view(
        buf1.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      final v2 = Uint64List.view(
        buf2.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      final v3 = Uint64List.view(
        buf3.buffer,
        viewOffsetBytes,
        viewLengthElements,
      );
      Expect.isTrue(v1.rangeEquals(0, viewLengthElements, v2));
      Expect.isFalse(v1.rangeEquals(0, viewLengthElements, v3));
    }
  }
}

void testLargeRanges() {
  const size = 64; // > 32 to exercise VM native memcmp and all chunking logic

  void checkLargeList<T extends List<int>>(
    String name,
    T Function(int len) creator,
    bool Function(T a, int start, int end, T b, [int otherStart]) tester,
  ) {
    final a = creator(size);
    final b = creator(size);
    for (int i = 0; i < size; i++) {
      a[i] = (i * 7 + 1) & 0x7F;
      b[i] = a[i];
    }
    // Full match
    Expect.isTrue(tester(a, 0, size, b, 0), '$name large full match');
    // Subrange match with count > 32
    Expect.isTrue(tester(a, 5, 50, b, 5), '$name large subrange match');
    // Subrange match with count > 32 at different offsets
    final c = creator(size + 10);
    for (int i = 0; i < size; i++) {
      c[i + 10] = a[i];
    }
    Expect.isTrue(tester(a, 5, 50, c, 15), '$name large offset subrange match');

    // Mismatch at first element
    b[0] = a[0] ^ 1;
    Expect.isFalse(tester(a, 0, size, b, 0), '$name large mismatch at first');
    b[0] = a[0];

    // Mismatch at middle element (index 35, > 32)
    b[35] = a[35] ^ 1;
    Expect.isFalse(tester(a, 0, size, b, 0), '$name large mismatch at mid');
    b[35] = a[35];

    // Mismatch at last element
    b[size - 1] = a[size - 1] ^ 1;
    Expect.isFalse(tester(a, 0, size, b, 0), '$name large mismatch at last');
    b[size - 1] = a[size - 1];
  }

  checkLargeList(
    'Uint8List',
    (n) => Uint8List(n),
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  checkLargeList(
    'Int8List',
    (n) => Int8List(n),
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  checkLargeList(
    'Uint8ClampedList',
    (n) => Uint8ClampedList(n),
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  checkLargeList(
    'Uint16List',
    (n) => Uint16List(n),
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  checkLargeList(
    'Int16List',
    (n) => Int16List(n),
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  checkLargeList(
    'Uint32List',
    (n) => Uint32List(n),
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  checkLargeList(
    'Int32List',
    (n) => Int32List(n),
    (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
  );
  if (supportsInt64) {
    checkLargeList(
      'Uint64List',
      (n) => Uint64List(n),
      (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
    );
    checkLargeList(
      'Int64List',
      (n) => Int64List(n),
      (a, s, e, b, [o = 0]) => a.rangeEquals(s, e, b, o),
    );
  }

  final bdA = ByteData(size);
  final bdB = ByteData(size);
  for (int i = 0; i < size; i++) {
    bdA.setUint8(i, (i * 7 + 1) & 0x7F);
    bdB.setUint8(i, bdA.getUint8(i));
  }
  Expect.isTrue(bdA.rangeEquals(0, size, bdB, 0));
  Expect.isTrue(bdA.rangeEquals(5, 50, bdB, 5));
  bdB.setUint8(35, bdA.getUint8(35) ^ 1);
  Expect.isFalse(bdA.rangeEquals(0, size, bdB, 0));
}

void testUnmodifiableViews() {
  final u8 = Uint8List.fromList([1, 2, 3, 4, 5]);
  final u8View = u8.asUnmodifiableView();
  final u8Copy = Uint8List.fromList([1, 2, 3, 4, 5]);
  final u8CopyView = u8Copy.asUnmodifiableView();
  final u8Diff = Uint8List.fromList([1, 2, 9, 4, 5]).asUnmodifiableView();

  Expect.isTrue(u8.rangeEquals(0, 5, u8View));
  Expect.isTrue(u8View.rangeEquals(0, 5, u8));
  Expect.isTrue(u8View.rangeEquals(0, 5, u8CopyView));
  Expect.isFalse(u8View.rangeEquals(0, 5, u8Diff));

  final bd = ByteData(4)
    ..setUint8(0, 10)
    ..setUint8(1, 20);
  final bdView = bd.asUnmodifiableView();
  final bdCopy = ByteData(4)
    ..setUint8(0, 10)
    ..setUint8(1, 20);
  final bdCopyView = bdCopy.asUnmodifiableView();
  final bdDiff = (ByteData(4)..setUint8(0, 99)).asUnmodifiableView();

  Expect.isTrue(bd.rangeEquals(0, 4, bdView));
  Expect.isTrue(bdView.rangeEquals(0, 4, bd));
  Expect.isTrue(bdView.rangeEquals(0, 4, bdCopyView));
  Expect.isFalse(bdView.rangeEquals(0, 4, bdDiff));
}

void main() {
  testUint8List();
  testInt8List();
  testUint8ClampedList();
  testUint16List();
  testInt16List();
  testUint32List();
  testInt32List();
  if (supportsInt64) {
    testUint64List();
    testInt64List();
  }
  testByteData();
  testByteDataChunking();
  testEmptyBuffers();
  testCrossViews();
  testSublistView();
  testViewsWithSurroundingGarbage();
  testLargeRanges();
  testUnmodifiableViews();
}
