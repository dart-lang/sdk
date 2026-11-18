// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:debug_info/debug_info.dart';
import 'package:debug_info/src/handles.dart';
import 'package:expect/expect.dart';

DebugInfo _handle(int index) =>
    DebugItemInternalMethods.makeDebugInfoHandle(index);

void expectAt(DebugInfoHandleReader reader, int offset, DebugInfo debugInfo) {
  Expect.equals(offset, reader.offset);
  Expect.equals(debugInfo, reader.handle);
}

void main() {
  testHandles();
  testEmpty();
  testSingleMapping();
  testShortDeltas();
  testByteDeltas();
  testGeneralDeltas();
  testUnmappedRegions();
  testDeltaAfterUnmapped();
  testDeduplicationAndOverwrite();
  testMoveUntil();
}

void testHandles() {
  Expect.isTrue(DebugItem.none.isNone);
  Expect.isFalse(DebugItem.none.isValid);
  Expect.isTrue(DebugInfo.none.isNone);
  Expect.isFalse(DebugInfo.none.isValid);
  Expect.isTrue(Scope.none.isNone);
  Expect.isFalse(Scope.none.isValid);
  Expect.equals(0, DebugInfo.none.rawValue);
  Expect.equals(-1, DebugInfo.none.index);

  final h1 = _handle(0);
  Expect.isFalse(h1.isNone);
  Expect.isTrue(h1.isValid);
  Expect.equals(0, h1.index);

  final h2 = _handle(1);
  Expect.isFalse(h2.isNone);
  Expect.isTrue(h2.isValid);
  Expect.equals(1, h2.index);

  final h3 = _handle(123456);
  Expect.equals(123456, h3.index);

  final hMax = _handle(0xffffffff);
  Expect.equals(0xffffffff, hMax.index);
}

void testEmpty() {
  final writer = DebugInfoHandleWriter();
  Expect.isTrue(writer.isEmpty);
  final bytes = writer.build();
  Expect.equals(0, bytes.length);
  Expect.isTrue(writer.isEmpty);

  final reader = DebugInfoHandleReader(bytes);
  expectAt(reader, 0, DebugInfo.none);
  Expect.isFalse(reader.moveNext());
}

void testSingleMapping() {
  final writer = DebugInfoHandleWriter();
  final h = _handle(10);
  writer.setInfo(0, h);
  Expect.isFalse(writer.isEmpty);

  final bytes = writer.build();
  Expect.isFalse(writer.isEmpty);

  final reader = DebugInfoHandleReader(bytes);
  expectAt(reader, 0, DebugInfo.none);
  Expect.isTrue(reader.moveNext());
  expectAt(reader, 0, h);
  Expect.isFalse(reader.moveNext());
}

void testShortDeltas() {
  final writer1 = DebugInfoHandleWriter();
  writer1.setInfo(0, _handle(20));
  final firstLen = writer1.build().length;

  // deltaOffset = 2, deltaHandle = 5 encodes in 1 byte.
  final writer2 = DebugInfoHandleWriter();
  writer2.setInfo(0, _handle(20));
  writer2.setInfo(2, _handle(25));
  final secondLen = writer2.build().length;
  Expect.equals(firstLen + 1, secondLen);

  // deltaOffset = 1, deltaHandle = 1 encodes in 1 byte.
  final writer3 = DebugInfoHandleWriter();
  writer3.setInfo(0, _handle(20));
  writer3.setInfo(2, _handle(25));
  writer3.setInfo(3, _handle(26));
  final thirdLen = writer3.build().length;
  Expect.equals(secondLen + 1, thirdLen);

  // deltaOffset = 8, deltaHandle = 15 encodes in 1 byte.
  final writer4 = DebugInfoHandleWriter();
  writer4.setInfo(0, _handle(20));
  writer4.setInfo(2, _handle(25));
  writer4.setInfo(3, _handle(26));
  writer4.setInfo(11, _handle(41));
  final fourthLen = writer4.build().length;
  Expect.equals(thirdLen + 1, fourthLen);

  final reader = writer4.reader;
  Expect.isTrue(reader.moveNext());
  expectAt(reader, 0, _handle(20));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 2, _handle(25));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 3, _handle(26));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 11, _handle(41));

  Expect.isFalse(reader.moveNext());
}

/// The length of the encoding of the first [count] of [entries].
int _encodedLength(List<(int, DebugInfo)> entries, int count) {
  final writer = DebugInfoHandleWriter();
  for (final (offset, handle) in entries.take(count)) {
    writer.setInfo(offset, handle);
  }
  return writer.build().length;
}

/// Checks that each of [entries] after the first adds the number of bytes in
/// [sizes], and that the entries read back.
void _expectEncoding(List<(int, DebugInfo)> entries, List<int> sizes) {
  for (var i = 0; i < sizes.length; i++) {
    Expect.equals(
      _encodedLength(entries, i + 1) + sizes[i],
      _encodedLength(entries, i + 2),
      'size of entry ${i + 1}',
    );
  }
  final writer = DebugInfoHandleWriter();
  for (final (offset, handle) in entries) {
    writer.setInfo(offset, handle);
  }
  final reader = writer.reader;
  for (final (offset, handle) in entries) {
    Expect.isTrue(reader.moveNext());
    expectAt(reader, offset, handle);
  }
  Expect.isFalse(reader.moveNext());
}

void testByteDeltas() {
  _expectEncoding(
    [
      (0, _handle(200)),
      // deltaOffset = 7, deltaHandle = -8 encodes in 2 bytes.
      (7, _handle(192)),
      // deltaOffset = 15, deltaHandle = 127 encodes in 2 bytes.
      (22, _handle(319)),
      // deltaOffset = 15, deltaHandle = -128 encodes in 2 bytes.
      (37, _handle(191)),
      // deltaOffset = 16 needs the multibyte move.
      (53, _handle(192)),
      // deltaHandle = 128 needs the multibyte move.
      (54, _handle(320)),
    ],
    [2, 2, 2, 3, 4],
  );
}

void testGeneralDeltas() {
  final writer = DebugInfoHandleWriter();
  writer.setInfo(0, _handle(100));
  // Offset delta 10 with small handle delta.
  writer.setInfo(10, _handle(101));
  // Large positive offset and handle deltas.
  writer.setInfo(210, _handle(500));
  // Negative handle delta outside short range.
  writer.setInfo(220, _handle(50));

  final reader = writer.reader;

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 0, _handle(100));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 10, _handle(101));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 210, _handle(500));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 220, _handle(50));

  Expect.isFalse(reader.moveNext());
}

void testUnmappedRegions() {
  final writer = DebugInfoHandleWriter();
  writer.setInfo(0, _handle(10));
  writer.clearInfo(5);
  writer.setInfo(10, _handle(15));
  writer.setInfo(15, DebugInfo.none);
  writer.setInfo(20, _handle(15));

  final reader = writer.reader;

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 0, _handle(10));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 5, DebugInfo.none);

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 10, _handle(15));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 15, DebugInfo.none);

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 20, _handle(15));

  Expect.isFalse(reader.moveNext());
}

void testDeltaAfterUnmapped() {
  _expectEncoding(
    [
      (0, _handle(10)),
      (5, DebugInfo.none),
      // A handle after unmapped code is a delta from the handle before it.
      (6, _handle(12)),
      (7, DebugInfo.none),
      (9, _handle(2)),
    ],
    [2, 1, 2, 2],
  );

  // A pending handle that is cleared is not the base of the next delta.
  final writer = DebugInfoHandleWriter();
  writer.setInfo(0, _handle(10));
  writer.setInfo(5, _handle(20));
  writer.clearInfo(5);
  writer.setInfo(8, _handle(23));

  final reader = writer.reader;
  Expect.isTrue(reader.moveNext());
  expectAt(reader, 0, _handle(10));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 5, DebugInfo.none);

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 8, _handle(23));

  Expect.isFalse(reader.moveNext());
}

void testDeduplicationAndOverwrite() {
  final writer = DebugInfoHandleWriter();

  writer.setInfo(0, _handle(10));
  // Duplicate handle at offset 5 is ignored.
  writer.setInfo(5, _handle(10));
  // Overwrite pending entry at offset 5 with a new handle.
  writer.setInfo(5, _handle(12));

  // Clear and then overwrite with a handle at the same offset.
  writer.clearInfo(8);
  writer.setInfo(8, _handle(20));

  // Set and then overwrite with clear at the same offset.
  writer.setInfo(10, _handle(30));
  writer.clearInfo(10);
  // Duplicate unmapped entry at offset 12 is ignored.
  writer.clearInfo(12);

  writer.setInfo(15, _handle(40));

  final reader = writer.reader;

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 0, _handle(10));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 5, _handle(12));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 8, _handle(20));

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 10, DebugInfo.none);

  Expect.isTrue(reader.moveNext());
  expectAt(reader, 15, _handle(40));

  Expect.isFalse(reader.moveNext());
}

void testMoveUntil() {
  final writer = DebugInfoHandleWriter();
  writer.setInfo(2, _handle(10));
  writer.setInfo(5, _handle(20));
  writer.clearInfo(8);
  writer.setInfo(12, _handle(30));

  final reader = writer.reader;

  // Target before first entry does not advance.
  Expect.isFalse(reader.moveUntil(1));
  expectAt(reader, 0, DebugInfo.none);

  // Exact match on first entry.
  Expect.isTrue(reader.moveUntil(2));
  expectAt(reader, 2, _handle(10));

  // Target between entries 2 and 5 stays at entry 2.
  Expect.isFalse(reader.moveUntil(4));
  expectAt(reader, 2, _handle(10));

  // Target skipping past 5 to 9 lands on entry 8.
  Expect.isTrue(reader.moveUntil(9));
  expectAt(reader, 8, DebugInfo.none);

  // Target past the last entry lands on entry 12.
  Expect.isTrue(reader.moveUntil(100));
  expectAt(reader, 12, _handle(30));

  // Subsequent moveUntil past the end does not advance and preserves current.
  Expect.isFalse(reader.moveUntil(200));
  expectAt(reader, 12, _handle(30));
}
