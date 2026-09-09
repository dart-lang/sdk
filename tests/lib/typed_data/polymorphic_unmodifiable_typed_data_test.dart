// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--inline_alloc
// VMOptions=--no_inline_alloc

import "dart:typed_data";

import "package:expect/expect.dart";

const bool supportsInt64 = bool.fromEnvironment("dart.isVM");
const int kListSize = 100;
const int kLoopSize = 1000;

@pragma("vm:never-inline")
readUint8(Uint8List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
writeUint8(Uint8List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

testUint8() {
  var internal = Uint8List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint8(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint8(internal);
  }

  var view = Uint8List.view(Uint8List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint8(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint8(view);
  }

  var unmodifiable = Uint8List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readUint8(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeUint8(unmodifiable));
  }
}

@pragma("vm:never-inline")
readInt8(Int8List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
writeInt8(Int8List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

testInt8() {
  var internal = Int8List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt8(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt8(internal);
  }

  var view = Int8List.view(Int8List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt8(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt8(view);
  }

  var unmodifiable = Int8List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readInt8(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeInt8(unmodifiable));
  }
}

@pragma("vm:never-inline")
readUint16(Uint16List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
writeUint16(Uint16List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

testUint16() {
  var internal = Uint16List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint16(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint16(internal);
  }

  var view = Uint16List.view(Uint16List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint16(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint16(view);
  }

  var unmodifiable = Uint16List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readUint16(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeUint16(unmodifiable));
  }
}

@pragma("vm:never-inline")
readInt16(Int16List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
writeInt16(Int16List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

testInt16() {
  var internal = Int16List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt16(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt16(internal);
  }

  var view = Int16List.view(Int16List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt16(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt16(view);
  }

  var unmodifiable = Int16List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readInt16(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeInt16(unmodifiable));
  }
}

@pragma("vm:never-inline")
readUint32(Uint32List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
writeUint32(Uint32List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

testUint32() {
  var internal = Uint32List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint32(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint32(internal);
  }

  var view = Uint32List.view(Uint32List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint32(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint32(view);
  }

  var unmodifiable = Uint32List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readUint32(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeUint32(unmodifiable));
  }
}

@pragma("vm:never-inline")
readInt32(Int32List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
writeInt32(Int32List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

testInt32() {
  var internal = Int32List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt32(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt32(internal);
  }

  var view = Int32List.view(Int32List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt32(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt32(view);
  }

  var unmodifiable = Int32List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readInt32(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeInt32(unmodifiable));
  }
}

@pragma("vm:never-inline")
readUint64(Uint64List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
writeUint64(Uint64List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

testUint64() {
  var internal = Uint64List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint64(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint64(internal);
  }

  var view = Uint64List.view(Uint64List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint64(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint64(view);
  }

  var unmodifiable = Uint64List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readUint64(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeUint64(unmodifiable));
  }
}

@pragma("vm:never-inline")
readInt64(Int64List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0, list[i]);
  }
}

@pragma("vm:never-inline")
writeInt64(Int64List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1;
  }
}

testInt64() {
  var internal = Int64List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt64(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt64(internal);
  }

  var view = Int64List.view(Int64List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt64(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt64(view);
  }

  var unmodifiable = Int64List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readInt64(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeInt64(unmodifiable));
  }
}

@pragma("vm:never-inline")
readFloat32(Float32List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0.0, list[i]);
  }
}

@pragma("vm:never-inline")
writeFloat32(Float32List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1.0;
  }
}

testFloat32() {
  var internal = Float32List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat32(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat32(internal);
  }

  var view = Float32List.view(Float32List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat32(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat32(view);
  }

  var unmodifiable = Float32List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readFloat32(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeFloat32(unmodifiable));
  }
}

@pragma("vm:never-inline")
readFloat64(Float64List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0.0, list[i]);
  }
}

@pragma("vm:never-inline")
writeFloat64(Float64List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = 1.0;
  }
}

testFloat64() {
  var internal = Float64List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat64(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat64(internal);
  }

  var view = Float64List.view(Float64List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat64(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat64(view);
  }

  var unmodifiable = Float64List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readFloat64(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeFloat64(unmodifiable));
  }
}

@pragma("vm:never-inline")
readInt32x4(Int32x4List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0, list[i].x);
    Expect.equals(0, list[i].y);
    Expect.equals(0, list[i].z);
    Expect.equals(0, list[i].w);
  }
}

@pragma("vm:never-inline")
writeInt32x4(Int32x4List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = Int32x4(1, 2, 3, 4);
  }
}

testInt32x4() {
  var internal = Int32x4List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt32x4(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt32x4(internal);
  }

  var view = Int32x4List.view(Int32x4List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt32x4(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt32x4(view);
  }

  var unmodifiable = Int32x4List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readInt32x4(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeInt32x4(unmodifiable));
  }
}

@pragma("vm:never-inline")
readFloat32x4(Float32x4List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0.0, list[i].x);
    Expect.equals(0.0, list[i].y);
    Expect.equals(0.0, list[i].z);
    Expect.equals(0.0, list[i].w);
  }
}

@pragma("vm:never-inline")
writeFloat32x4(Float32x4List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = Float32x4(1.0, 2.0, 3.0, 4.0);
  }
}

testFloat32x4() {
  var internal = Float32x4List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat32x4(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat32x4(internal);
  }

  var view = Float32x4List.view(Float32x4List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat32x4(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat32x4(view);
  }

  var unmodifiable = Float32x4List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readFloat32x4(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeFloat32x4(unmodifiable));
  }
}

@pragma("vm:never-inline")
readFloat64x2(Float64x2List list) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(0.0, list[i].x);
    Expect.equals(0.0, list[i].y);
  }
}

@pragma("vm:never-inline")
writeFloat64x2(Float64x2List list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = Float64x2(1.0, 2.0);
  }
}

testFloat64x2() {
  var internal = Float64x2List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat64x2(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat64x2(internal);
  }

  var view = Float64x2List.view(Float64x2List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat64x2(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat64x2(view);
  }

  var unmodifiable = Float64x2List(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readFloat64x2(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeFloat64x2(unmodifiable));
  }
}

@pragma("vm:never-inline")
readByteData(ByteData data) {
  for (int i = 0; i < data.lengthInBytes; i++) {
    Expect.equals(0, data.getUint8(i));
  }
}

@pragma("vm:never-inline")
writeByteData(ByteData data) {
  for (int i = 0; i < data.lengthInBytes; i++) {
    data.setUint8(i, 1);
  }
}

testByteData() {
  var internal = ByteData(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readByteData(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeByteData(internal);
  }

  var view = ByteData.view(ByteData(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readByteData(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeByteData(view);
  }

  var unmodifiable = ByteData(kListSize).asUnmodifiableView();
  for (var i = 0; i < kLoopSize; i++) {
    readByteData(unmodifiable);
  }
  for (var i = 0; i < kLoopSize; i++) {
    Expect.throwsUnsupportedError(() => writeByteData(unmodifiable));
  }
}

main() {
  testUint8();
  testInt8();
  testUint16();
  testInt16();
  testUint32();
  testInt32();
  if (supportsInt64) {
    testUint64();
    testInt64();
  }
  testFloat32();
  testFloat64();
  testInt32x4();
  testFloat32x4();
  testFloat64x2();
  testByteData();
}
