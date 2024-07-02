// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--inline_alloc
// VMOptions=--no_inline_alloc

import 'dart:typed_data';
import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

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

checkIndirectUnmodifiable(TypedData data) {
  var newView1 = data.buffer.asUint8List();
  Expect.throwsUnsupportedError(() => newView1[0] = 1);
  var newView2 = Uint8List.view(data.buffer);
  Expect.throwsUnsupportedError(() => newView2[0] = 1);
}

int8ListTest() {
  Int8List i8l = new Int8List.fromList(intList);
  Int8List list = i8l.asUnmodifiableView();
  checkReadable(list);
  checkUnmodifiable(list);
  checkIndirectUnmodifiable(list);
}

uint8ListTest() {
  Uint8List u8l = new Uint8List.fromList(intList);
  Uint8List list = u8l.asUnmodifiableView();
  checkReadable(list);
  checkUnmodifiable(list);
  checkIndirectUnmodifiable(list);
}

uint8ClampedListTest() {
  Uint8ClampedList u8l = new Uint8ClampedList.fromList(intList);
  Uint8ClampedList list = u8l.asUnmodifiableView();
  checkReadable(list);
  checkUnmodifiable(list);
  checkIndirectUnmodifiable(list);
}

int16ListTest() {
  Int16List i16l = new Int16List.fromList(intList);
  Int16List list = i16l.asUnmodifiableView();
  checkReadable(list);
  checkUnmodifiable(list);
  checkIndirectUnmodifiable(list);
}

uint16ListTest() {
  Uint16List u16l = new Uint16List.fromList(intList);
  Uint16List list = u16l.asUnmodifiableView();
  checkReadable(list);
  checkUnmodifiable(list);
  checkIndirectUnmodifiable(list);
}

int32ListTest() {
  Int32List i32l = new Int32List.fromList(intList);
  Int32List list = i32l.asUnmodifiableView();
  checkReadable(list);
  checkUnmodifiable(list);
  checkIndirectUnmodifiable(list);
}

uint32ListTest() {
  Uint32List u32l = new Uint32List.fromList(intList);
  Uint32List list = u32l.asUnmodifiableView();
  checkReadable(list);
  checkUnmodifiable(list);
  checkIndirectUnmodifiable(list);
}

int64ListTest() {
  Int64List i64l = new Int64List.fromList(intList);
  Int64List list = i64l.asUnmodifiableView();
  checkReadable(list);
  checkUnmodifiable(list);
  checkIndirectUnmodifiable(list);
}

uint64ListTest() {
  Uint64List u64l = new Uint64List.fromList(intList);
  Uint64List list = u64l.asUnmodifiableView();
  checkReadable(list);
  checkUnmodifiable(list);
  checkIndirectUnmodifiable(list);
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
  Float32List list = f32l.asUnmodifiableView();
  checkDoubleReadable(list);
  checkDoubleUnmodifiable(list);
  checkIndirectUnmodifiable(list);
}

float64ListTest() {
  Float64List f64l = new Float64List.fromList(doubleList);
  Float64List list = f64l.asUnmodifiableView();
  checkDoubleReadable(list);
  checkDoubleUnmodifiable(list);
  checkIndirectUnmodifiable(list);
}

byteDataTest() {
  ByteBuffer buffer = new Uint8List.fromList(intList).buffer;
  ByteData bd = new ByteData.view(buffer);
  ByteData ubdv = bd.asUnmodifiableView();

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

  checkIndirectUnmodifiable(ubdv);
}

main() {
  int8ListTest();
  uint8ListTest();
  uint8ClampedListTest();
  int16ListTest();
  uint16ListTest();
  int32ListTest();
  uint32ListTest();
  if (!jsNumbers) {
    int64ListTest();
    uint64ListTest();
  }
  float32ListTest();
  float64ListTest();
  byteDataTest();
}
