// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';

const bool isJS = identical(1, 1.0); // Implies no 64-bit integers.

void main() {
  testViews();
  testErrors();
}

void testViews() {
  var bytes = Uint8List.fromList([for (int i = 0; i < 256; i++) i]);

  // Non-view classes.
  var bd = () {
    var bd = ByteData(256);
    for (int i = 0; i < 256; i++) bd.setUint8(i, i);
    return bd;
  }();
  var u8 = Uint8List.fromList(bytes);
  var i8 = Int8List.fromList(bytes);
  var c8 = Uint8ClampedList.fromList(bytes);
  var u16 = Uint16List.fromList(Uint16List.view(bytes.buffer));
  var i16 = Int16List.fromList(Int16List.view(bytes.buffer));
  var u32 = Uint32List.fromList(Uint32List.view(bytes.buffer));
  var i32 = Int32List.fromList(Int32List.view(bytes.buffer));
  var u64 = isJS ? null : Uint64List.fromList(Uint64List.view(bytes.buffer));
  var i64 = isJS ? null : Int64List.fromList(Int64List.view(bytes.buffer));
  var f32 = Float32List.fromList(Float32List.view(bytes.buffer));
  var f64 = Float64List.fromList(Float64List.view(bytes.buffer));
  var f32x4 = Float32x4List.fromList(Float32x4List.view(bytes.buffer));
  var i32x4 = Int32x4List.fromList(Int32x4List.view(bytes.buffer));
  var f64x2 = Float64x2List.fromList(Float64x2List.view(bytes.buffer));

  // View classes. A buffer with the right data in the middle.
  var doubleBuffer = Uint8List(512)..setRange(128, 384, bytes);
  var bdv = ByteData.view(doubleBuffer.buffer, 128, 256);
  var u8v = Uint8List.view(doubleBuffer.buffer, 128, 256);
  var i8v = Int8List.view(doubleBuffer.buffer, 128, 256);
  var c8v = Uint8ClampedList.view(doubleBuffer.buffer, 128, 256);
  var u16v = Uint16List.view(doubleBuffer.buffer, 128, 128);
  var i16v = Int16List.view(doubleBuffer.buffer, 128, 128);
  var u32v = Uint32List.view(doubleBuffer.buffer, 128, 64);
  var i32v = Int32List.view(doubleBuffer.buffer, 128, 64);
  var u64v = isJS ? null : Uint64List.view(doubleBuffer.buffer, 128, 32);
  var i64v = isJS ? null : Int64List.view(doubleBuffer.buffer, 128, 32);
  var f32v = Float32List.view(doubleBuffer.buffer, 128, 64);
  var f64v = Float64List.view(doubleBuffer.buffer, 128, 32);
  var f32x4v = Float32x4List.view(doubleBuffer.buffer, 128, 16);
  var i32x4v = Int32x4List.view(doubleBuffer.buffer, 128, 16);
  var f64x2v = Float64x2List.view(doubleBuffer.buffer, 128, 16);

  var allTypedData = <TypedData>[
    bd,
    u8,
    i8,
    c8,
    u16,
    i16,
    u32,
    i32,
    if (!isJS) u64,
    if (!isJS) i64,
    f32,
    f64,
    f32x4,
    i32x4,
    f64x2,
    u8v,
    i8v,
    c8v,
    u16v,
    i16v,
    u32v,
    i32v,
    if (!isJS) u64v,
    if (!isJS) i64v,
    f32v,
    f64v,
    f32x4v,
    i32x4v,
    f64x2v,
  ];

  for (var td in allTypedData) {
    var tdType = td.runtimeType.toString();
    testSame(TypedData data) {
      expectBuffer(td.buffer, data.buffer);
      Expect.equals(td.lengthInBytes, data.lengthInBytes);
      Expect.equals(td.offsetInBytes, data.offsetInBytes);
    }

    testSame(ByteData.sublistView(td));
    testSame(Int8List.sublistView(td));
    testSame(Uint8List.sublistView(td));
    testSame(Uint8ClampedList.sublistView(td));
    testSame(Int16List.sublistView(td));
    testSame(Uint16List.sublistView(td));
    testSame(Int32List.sublistView(td));
    testSame(Uint32List.sublistView(td));
    if (!isJS) testSame(Int64List.sublistView(td));
    if (!isJS) testSame(Uint64List.sublistView(td));
    testSame(Float32List.sublistView(td));
    testSame(Float64List.sublistView(td));
    testSame(Float32x4List.sublistView(td));
    testSame(Int32x4List.sublistView(td));
    testSame(Float64x2List.sublistView(td));

    var length = td.lengthInBytes ~/ td.elementSizeInBytes;
    for (int start = 0; start < length; start += 16) {
      for (int end = start; end < length; end += 16) {
        void testSlice(TypedData data) {
          var name = "$tdType -> ${data.runtimeType} $start..$end";
          expectBuffer(td.buffer, data.buffer, name);
          int offsetInBytes = td.offsetInBytes + start * td.elementSizeInBytes;
          int lengthInBytes = (end - start) * td.elementSizeInBytes;
          Expect.equals(lengthInBytes, data.lengthInBytes, name);
          Expect.equals(offsetInBytes, data.offsetInBytes, name);
        }

        testSlice(ByteData.sublistView(td, start, end));
        testSlice(Int8List.sublistView(td, start, end));
        testSlice(Uint8List.sublistView(td, start, end));
        testSlice(Uint8ClampedList.sublistView(td, start, end));
        testSlice(Int16List.sublistView(td, start, end));
        testSlice(Uint16List.sublistView(td, start, end));
        testSlice(Int32List.sublistView(td, start, end));
        testSlice(Uint32List.sublistView(td, start, end));
        if (!isJS) testSlice(Int64List.sublistView(td, start, end));
        if (!isJS) testSlice(Uint64List.sublistView(td, start, end));
        testSlice(Float32List.sublistView(td, start, end));
        testSlice(Float64List.sublistView(td, start, end));
        testSlice(Float32x4List.sublistView(td, start, end));
        testSlice(Int32x4List.sublistView(td, start, end));
        testSlice(Float64x2List.sublistView(td, start, end));
      }
    }
  }
}

void testErrors() {
  // Alignment must be right for non-byte-sized results.
  // offsetInBytes offset must be a multiple of the element size.
  // lengthInBytes must be a multiple of the element size.
  var bytes = Uint8List.fromList([for (int i = 0; i < 256; i++) i]);

  var oddStartView = Uint8List.view(bytes.buffer, 1, 32);
  var oddLengthView = Uint8List.view(bytes.buffer, 0, 33);

  void testThrows(void Function() operation) {
    Expect.throws<ArgumentError>(operation);
  }

  testThrows(() => Uint16List.sublistView(oddStartView));
  testThrows(() => Int16List.sublistView(oddStartView));
  testThrows(() => Uint32List.sublistView(oddStartView));
  testThrows(() => Int32List.sublistView(oddStartView));
  if (!isJS) testThrows(() => Uint64List.sublistView(oddStartView));
  if (!isJS) testThrows(() => Int64List.sublistView(oddStartView));
  testThrows(() => Float32List.sublistView(oddStartView));
  testThrows(() => Float64List.sublistView(oddStartView));
  testThrows(() => Float32x4List.sublistView(oddStartView));
  testThrows(() => Int32x4List.sublistView(oddStartView));
  testThrows(() => Float64x2List.sublistView(oddStartView));

  testThrows(() => Uint16List.sublistView(oddLengthView));
  testThrows(() => Int16List.sublistView(oddLengthView));
  testThrows(() => Uint32List.sublistView(oddLengthView));
  testThrows(() => Int32List.sublistView(oddLengthView));
  if (!isJS) testThrows(() => Uint64List.sublistView(oddLengthView));
  if (!isJS) testThrows(() => Int64List.sublistView(oddLengthView));
  testThrows(() => Float32List.sublistView(oddLengthView));
  testThrows(() => Float64List.sublistView(oddLengthView));
  testThrows(() => Float32x4List.sublistView(oddLengthView));
  testThrows(() => Int32x4List.sublistView(oddLengthView));
  testThrows(() => Float64x2List.sublistView(oddLengthView));
}

void expectBuffer(ByteBuffer buffer, ByteBuffer dataBuffer, [String name]) {
  // Buffer objects are not necessarily *identical* even though they
  // represent the same underlying data. The VM allocates buffer objects
  // lazily for inline typed data objects.
  if (identical(buffer, dataBuffer)) return;
  if (buffer.lengthInBytes != dataBuffer.lengthInBytes) {
    Expect.fail("Different buffers${name == null ? "" : ": $name"}");
  }
  // Cannot distinguish empty buffers.
  if (buffer.lengthInBytes == 0) return;
  // Contains the same value now.
  var l1 = Uint8List.view(buffer);
  var l2 = Uint8List.view(dataBuffer);
  var byte1 = l1[0];
  var byte2 = l2[0];
  if (byte1 != byte2) {
    Expect.fail("Different buffers${name == null ? "" : ": $name"}");
  }
  // Byte written to one buffer can be read from the other.
  var newByte1 = byte1 ^ 1;
  l1[0] = newByte1;
  var newByte2 = l2[0];
  l1[0] = byte1;
  if (newByte1 != newByte2) {
    Expect.fail("Different buffers${name == null ? "" : ": $name"}");
  }
}
