// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';

const bool supportsInt64 = bool.fromEnvironment('dart.isVM');

List<int> intList = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

checkReadable(List<int> list) {
  for (int i = 0; i < intList.length; i++) {
    Expect.equals(list[i], intList[i]);
  }
}

checkUnmodifiable(List<int> list) {
  var zero = 0;
  var one = 1;
  var two = 2;
  Expect.throwsUnsupportedError(() => list.add(zero));
  Expect.throwsUnsupportedError(() => list.addAll([one, two]));
  Expect.throwsUnsupportedError(() => list.clear());
  Expect.throwsUnsupportedError(() => list.insert(0, zero));
  Expect.throwsUnsupportedError(() => list.insertAll(0, [one, two]));
  Expect.throwsUnsupportedError(() => list.remove(one));
  Expect.throwsUnsupportedError(() => list.removeAt(0));
  Expect.throwsUnsupportedError(() => list.removeLast());
  Expect.throwsUnsupportedError(() => list.removeRange(0, 1));
  Expect.throwsUnsupportedError(() => list.removeWhere((x) => true));
  Expect.throwsUnsupportedError(() => list.replaceRange(0, 1, []));
  Expect.throwsUnsupportedError(() => list.retainWhere((x) => false));
  Expect.throwsUnsupportedError(() => list[0] = zero);
  Expect.throwsUnsupportedError(() => list.setRange(0, 1, [one]));
  Expect.throwsUnsupportedError(() => list.setAll(0, [one]));
}

int8ListTest() {
  Int8List i8l = new Int8List.fromList(intList);
  UnmodifiableInt8ListView list = new UnmodifiableInt8ListView(i8l);
  checkReadable(list);
  checkUnmodifiable(list);
}

uint8ListTest() {
  Uint8List u8l = new Uint8List.fromList(intList);
  UnmodifiableUint8ListView list = new UnmodifiableUint8ListView(u8l);
  checkReadable(list);
  checkUnmodifiable(list);
}

int16ListTest() {
  Int16List i16l = new Int16List.fromList(intList);
  UnmodifiableInt16ListView list = new UnmodifiableInt16ListView(i16l);
  checkReadable(list);
  checkUnmodifiable(list);
}

uint16ListTest() {
  Uint16List u16l = new Uint16List.fromList(intList);
  UnmodifiableUint16ListView list = new UnmodifiableUint16ListView(u16l);
  checkReadable(list);
  checkUnmodifiable(list);
}

int32ListTest() {
  Int32List i32l = new Int32List.fromList(intList);
  UnmodifiableInt32ListView list = new UnmodifiableInt32ListView(i32l);
  checkReadable(list);
  checkUnmodifiable(list);
}

uint32ListTest() {
  Uint32List u32l = new Uint32List.fromList(intList);
  UnmodifiableUint32ListView list = new UnmodifiableUint32ListView(u32l);
  checkReadable(list);
  checkUnmodifiable(list);
}

int64ListTest() {
  Int64List i64l = new Int64List.fromList(intList);
  UnmodifiableInt64ListView list = new UnmodifiableInt64ListView(i64l);
  checkReadable(list);
  checkUnmodifiable(list);
}

uint64ListTest() {
  Uint64List u64l = new Uint64List.fromList(intList);
  UnmodifiableUint64ListView list = new UnmodifiableUint64ListView(u64l);
  checkReadable(list);
  checkUnmodifiable(list);
}

List<double> doubleList = <double>[1.0, 2.0, 3.0, 4.0, 5.0];

checkDoubleReadable(List<double> list) {
  for (int i = 0; i < doubleList.length; i++) {
    Expect.equals(list[i], doubleList[i]);
  }
}

checkDoubleUnmodifiable(List<double> list) {
  var zero = 0.0;
  var one = 1.0;
  var two = 2.0;
  Expect.throwsUnsupportedError(() => list.add(zero));
  Expect.throwsUnsupportedError(() => list.addAll([one, two]));
  Expect.throwsUnsupportedError(() => list.clear());
  Expect.throwsUnsupportedError(() => list.insert(0, zero));
  Expect.throwsUnsupportedError(() => list.insertAll(0, [one, two]));
  Expect.throwsUnsupportedError(() => list.remove(one));
  Expect.throwsUnsupportedError(() => list.removeAt(0));
  Expect.throwsUnsupportedError(() => list.removeLast());
  Expect.throwsUnsupportedError(() => list.removeRange(0, 1));
  Expect.throwsUnsupportedError(() => list.removeWhere((x) => true));
  Expect.throwsUnsupportedError(() => list.replaceRange(0, 1, []));
  Expect.throwsUnsupportedError(() => list.retainWhere((x) => false));
  Expect.throwsUnsupportedError(() => list[0] = zero);
  Expect.throwsUnsupportedError(() => list.setRange(0, 1, [one]));
  Expect.throwsUnsupportedError(() => list.setAll(0, [one]));
}

float32ListTest() {
  Float32List f32l = new Float32List.fromList(doubleList);
  UnmodifiableFloat32ListView list = new UnmodifiableFloat32ListView(f32l);
  checkDoubleReadable(list);
  checkDoubleUnmodifiable(list);
}

float64ListTest() {
  Float64List f64l = new Float64List.fromList(doubleList);
  UnmodifiableFloat64ListView list = new UnmodifiableFloat64ListView(f64l);
  checkDoubleReadable(list);
  checkDoubleUnmodifiable(list);
}

byteDataTest() {
  ByteBuffer buffer = new Uint8List.fromList(intList).buffer;
  ByteData bd = new ByteData.view(buffer);
  UnmodifiableByteDataView ubdv = new UnmodifiableByteDataView(bd);

  Expect.throwsUnsupportedError(() => ubdv.setInt8(0, 0));
  Expect.throwsUnsupportedError(() => ubdv.setUint8(0, 0));
  Expect.throwsUnsupportedError(() => ubdv.setInt16(0, 0));
  Expect.throwsUnsupportedError(() => ubdv.setUint16(0, 0));
  Expect.throwsUnsupportedError(() => ubdv.setInt32(0, 0));
  Expect.throwsUnsupportedError(() => ubdv.setUint32(0, 0));
  Expect.throwsUnsupportedError(() => ubdv.setInt64(0, 0));
  Expect.throwsUnsupportedError(() => ubdv.setUint64(0, 0));
  Expect.throwsUnsupportedError(() => ubdv.setFloat32(0, 0.0));
  Expect.throwsUnsupportedError(() => ubdv.setFloat64(0, 0.0));
}

main() {
  int8ListTest();
  uint8ListTest();
  int16ListTest();
  uint16ListTest();
  int32ListTest();
  uint32ListTest();
  if (supportsInt64) {
    int64ListTest();
    uint64ListTest();
  }
  float32ListTest();
  float64ListTest();
  byteDataTest();
}
