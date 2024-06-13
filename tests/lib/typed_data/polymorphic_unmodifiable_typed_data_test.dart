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
  var internal = new Uint8List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint8(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint8(internal);
  }

  var view = new Uint8List.view(new Uint8List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint8(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint8(view);
  }

  var unmodifiable = new Uint8List(kListSize).asUnmodifiableView();
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
  var internal = new Int8List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt8(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt8(internal);
  }

  var view = new Int8List.view(new Int8List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt8(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt8(view);
  }

  var unmodifiable = new Int8List(kListSize).asUnmodifiableView();
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
  var internal = new Uint16List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint16(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint16(internal);
  }

  var view =
      new Uint16List.view(new Uint16List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint16(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint16(view);
  }

  var unmodifiable = new Uint16List(kListSize).asUnmodifiableView();
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
  var internal = new Int16List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt16(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt16(internal);
  }

  var view = new Int16List.view(new Int16List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt16(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt16(view);
  }

  var unmodifiable = new Int16List(kListSize).asUnmodifiableView();
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
  var internal = new Uint32List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint32(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint32(internal);
  }

  var view =
      new Uint32List.view(new Uint32List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint32(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint32(view);
  }

  var unmodifiable = new Uint32List(kListSize).asUnmodifiableView();
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
  var internal = new Int32List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt32(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt32(internal);
  }

  var view = new Int32List.view(new Int32List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt32(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt32(view);
  }

  var unmodifiable = new Int32List(kListSize).asUnmodifiableView();
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
  var internal = new Uint64List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint64(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint64(internal);
  }

  var view =
      new Uint64List.view(new Uint64List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readUint64(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeUint64(view);
  }

  var unmodifiable = new Uint64List(kListSize).asUnmodifiableView();
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
  var internal = new Int64List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt64(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt64(internal);
  }

  var view = new Int64List.view(new Int64List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt64(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt64(view);
  }

  var unmodifiable = new Int64List(kListSize).asUnmodifiableView();
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
  var internal = new Float32List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat32(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat32(internal);
  }

  var view =
      new Float32List.view(new Float32List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat32(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat32(view);
  }

  var unmodifiable = new Float32List(kListSize).asUnmodifiableView();
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
  var internal = new Float64List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat64(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat64(internal);
  }

  var view =
      new Float64List.view(new Float64List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat64(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat64(view);
  }

  var unmodifiable = new Float64List(kListSize).asUnmodifiableView();
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
  var internal = new Int32x4List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt32x4(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt32x4(internal);
  }

  var view =
      new Int32x4List.view(new Int32x4List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readInt32x4(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeInt32x4(view);
  }

  var unmodifiable = new Int32x4List(kListSize).asUnmodifiableView();
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
  var internal = new Float32x4List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat32x4(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat32x4(internal);
  }

  var view =
      new Float32x4List.view(new Float32x4List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat32x4(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat32x4(view);
  }

  var unmodifiable = new Float32x4List(kListSize).asUnmodifiableView();
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
  var internal = new Float64x2List(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat64x2(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat64x2(internal);
  }

  var view =
      new Float64x2List.view(new Float64x2List(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readFloat64x2(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeFloat64x2(view);
  }

  var unmodifiable = new Float64x2List(kListSize).asUnmodifiableView();
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
  var internal = new ByteData(kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readByteData(internal);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeByteData(internal);
  }

  var view = new ByteData.view(new ByteData(kListSize).buffer, 0, kListSize);
  for (var i = 0; i < kLoopSize; i++) {
    readByteData(view);
  }
  for (var i = 0; i < kLoopSize; i++) {
    writeByteData(view);
  }

  var unmodifiable = new ByteData(kListSize).asUnmodifiableView();
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
