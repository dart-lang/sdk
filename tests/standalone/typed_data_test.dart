// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing typed data.

// Library tag to be able to run in html test framework.
library TypedDataTest;

import 'dart:typeddata';

void testCreateUint8TypedData() {
  Uint8List typed_data;

  typed_data = new Uint8List(0);
  Expect.isTrue(typed_data is Uint8List);
  Expect.isFalse(typed_data is Uint8ClampedList);
  Expect.equals(0, typed_data.length);

  typed_data = new Uint8List(10);
  Expect.equals(10, typed_data.length);
  for (int i = 0; i < 10; i++) {
    Expect.equals(0, typed_data[i]);
  }
}

void testCreateClampedUint8TypedData() {
  Uint8ClampedList typed_data;

  typed_data = new Uint8ClampedList(0);
  Expect.isTrue(typed_data is Uint8ClampedList);
  Expect.isFalse(typed_data is Uint8List);
  Expect.equals(0, typed_data.length);
  Expect.equals(0, typed_data.lengthInBytes);

  typed_data = new Uint8ClampedList(10);
  Expect.equals(10, typed_data.length);
  for (int i = 0; i < 10; i++) {
    Expect.equals(0, typed_data[i]);
  }
}

void testCreateExternalClampedUint8TypedData() {
  List typed_data;

  typed_data = new Uint8ClampedList.transferable(0);
  Expect.isTrue(typed_data is Uint8ClampedList);
  Expect.isFalse(typed_data is Uint8List);
  Expect.equals(0, typed_data.length);
  Expect.equals(0, typed_data.lengthInBytes);

  typed_data = new Uint8ClampedList.transferable(10);
  Expect.equals(10, typed_data.length);
  for (int i = 0; i < 10; i++) {
    Expect.equals(0, typed_data[i]);
  }

  typed_data[0] = -1;
  Expect.equals(0, typed_data[0]);

  for (int i = 0; i < 10; i++) {
    typed_data[i] = i + 250;
  }
  for (int i = 0; i < 10; i++) {
    Expect.equals(i + 250 > 255 ? 255 : i + 250, typed_data[i]);
  }
}

void testTypedDataRange(bool check_throws) {
  Int8List typed_data;
  typed_data = new Int8List(10);
  typed_data[1] = 0;
  Expect.equals(0, typed_data[1]);
  typed_data[2] = -128;
  Expect.equals(-128, typed_data[2]);
  typed_data[3] = 127;
  Expect.equals(127, typed_data[3]);
  // This should eventually throw.
  typed_data[0] = 128;
  typed_data[4] = -129;
  if (check_throws) {
    Expect.throws(() {
      typed_data[1] = 1.2;
    });
  }
}

void testUnsignedTypedDataRange(bool check_throws) {
  Uint8List typed_data;
  typed_data = new Uint8List(10);

  typed_data[1] = 255;
  Expect.equals(255, typed_data[1]);
  typed_data[1] = 0;
  Expect.equals(0, typed_data[1]);

  for (int i = 0; i < typed_data.length; i++) {
    typed_data[i] = i;
  }
  for (int i = 0; i < typed_data.length; i++) {
    Expect.equals(i, typed_data[i]);
  }

  // These should eventually throw.
  typed_data[1] = 256;
  typed_data[1] = -1;
  typed_data[2] = -129;
  if (check_throws) {
    Expect.throws(() {
      typed_data[1] = 1.2;
    });
  }
}

void testClampedUnsignedTypedDataRangeHelper(Uint8ClampedList typed_data,
                                             bool check_throws) {
  Uint8ClampedList typed_data;
  typed_data = new Uint8ClampedList(10);

  typed_data[1] = 255;
  Expect.equals(255, typed_data[1]);
  typed_data[1] = 0;
  Expect.equals(0, typed_data[1]);
  for (int i = 0; i < typed_data.length; i++) {
    typed_data[i] = i;
  }
  for (int i = 0; i < typed_data.length; i++) {
    Expect.equals(i, typed_data[i]);
  }

  // These should eventually throw.
  typed_data[1] = 256;
  typed_data[2] = -129;
  Expect.equals(255, typed_data[1]);
  Expect.equals(0, typed_data[2]);
}

void testClampedUnsignedTypedDataRange(bool check_throws) {
  testClampedUnsignedTypedDataRangeHelper(new Uint8ClampedList(10),
                                          check_throws);
}

void testExternalClampedUnsignedTypedDataRange(bool check_throws) {
  testClampedUnsignedTypedDataRangeHelper(new Uint8ClampedList.transferable(10),
                                          check_throws);
}

void testSetRangeHelper(typed_data) {
  List<int> list = [10, 11, 12];
  typed_data.setRange(0, 3, list);
  for (int i = 0; i < 3; i++) {
    Expect.equals(10 + i, typed_data[i]);
  }

  typed_data[0] = 20;
  typed_data[1] = 21;
  typed_data[2] = 22;
  list.setRange(0, 3, typed_data);
  for (int i = 0; i < 3; i++) {
    Expect.equals(20 + i, list[i]);
  }

  typed_data.setRange(1, 2, const [8, 9]);
  Expect.equals(20, typed_data[0]);
  Expect.equals(8, typed_data[1]);
  Expect.equals(9, typed_data[2]);
}

void testSetRange() {
  testSetRangeHelper(new Uint8List(3));
  testSetRangeHelper(new Uint8List.transferable(3));
  testSetRangeHelper(new Uint8ClampedList(3));
  testSetRangeHelper(new Uint8ClampedList.transferable(3));
}

void testIndexOutOfRangeHelper(typed_data) {
  List<int> list = const [0, 1, 2, 3];

  Expect.throws(() {
    typed_data.setRange(0, 4, list);
  });

  Expect.throws(() {
    typed_data.setRange(3, 1, list);
  });
}

void testIndexOutOfRange() {
  testIndexOutOfRangeHelper(new Uint8List(3));
  testIndexOutOfRangeHelper(new Uint8List.transferable(3));
  testIndexOutOfRangeHelper(new Uint8ClampedList(3));
  testIndexOutOfRangeHelper(new Uint8ClampedList.transferable(3));
}

void testIndexOfHelper(list) {
  for (int i = 0; i < list.length; i++) {
    list[i] = i + 10;
  }
  Expect.equals(0, list.indexOf(10));
  Expect.equals(5, list.indexOf(15));
  Expect.equals(9, list.indexOf(19));
  Expect.equals(-1, list.indexOf(20));

  list = new Float32List(10);
  for (int i = 0; i < list.length; i++) {
    list[i] = i + 10.0;
  }
  Expect.equals(0, list.indexOf(10.0));
  Expect.equals(5, list.indexOf(15.0));
  Expect.equals(9, list.indexOf(19.0));
  Expect.equals(-1, list.indexOf(20.0));
}

void testIndexOf() {
  testIndexOfHelper(new Uint8List.transferable(10));
  testIndexOfHelper(new Uint8ClampedList(10));
  testIndexOfHelper(new Uint8ClampedList.transferable(10));
}

void testGetAtIndex() {
  var list = new Uint8List(8);
  for (int i = 0; i < list.length; i++) {
    list[i] = 42;
  }
  var bdata = new ByteData.view(list);
  for (int i = 0; i < list.length; i++) {
    Expect.equals(42, bdata.getUint8(i));
    Expect.equals(42, bdata.getInt8(i));
  }
  for (int i = 0; i < list.length ~/ 2; i++) {
    Expect.equals(10794, bdata.getUint16(i));
    Expect.equals(10794, bdata.getInt16(i));
  }
  for (int i = 0; i < list.length ~/ 4; i++) {
    Expect.equals(707406378, bdata.getUint32(i));
    Expect.equals(707406378, bdata.getInt32(i));
    Expect.equals(1.511366173271439e-13, bdata.getFloat32(i));
  }
  for (int i = 0; i < list.length ~/ 8; i++) {
    Expect.equals(3038287259199220266, bdata.getUint64(i));
    Expect.equals(3038287259199220266, bdata.getInt64(i));
    Expect.equals(1.4260258159703532e-105, bdata.getFloat64(i));
  }
}

void testSetAtIndex() {
  var list = new Uint8List(8);
  void validate() {
    for (int i = 0; i < list.length; i++) {
      Expect.equals(42, list[i]);
    }
  }
  var bdata = new ByteData.view(list);
  for (int i = 0; i < list.length; i++) bdata.setUint8(i, 42);
  validate();
  for (int i = 0; i < list.length; i++) bdata.setInt8(i, 42);
  validate();
  for (int i = 0; i < list.length ~/ 2; i++) bdata.setUint16(i, 10794);
  validate();
  for (int i = 0; i < list.length ~/ 2; i++) bdata.setInt16(i, 10794);
  validate();
  for (int i = 0; i < list.length ~/ 4; i++) bdata.setUint32(i, 707406378);
  validate();
  for (int i = 0; i < list.length ~/ 4; i++) bdata.setInt32(i, 707406378);
  validate();
  for (int i = 0; i < list.length ~/ 4; i++) {
    bdata.setFloat32(i, 1.511366173271439e-13);
  }
  validate();
  for (int i = 0; i < list.length ~/ 8; i++) {
    bdata.setUint64(i, 3038287259199220266);
  }
  validate();
  for (int i = 0; i < list.length ~/ 8; i++) {
    bdata.setInt64(i, 3038287259199220266);
  }
  validate();
  for (int i = 0; i < list.length ~/ 8; i++) {
    bdata.setFloat64(i, 1.4260258159703532e-105);
  }
  validate();
}

main() {
  for (int i = 0; i < 2000; i++) {
    testCreateUint8TypedData();
    testCreateClampedUint8TypedData();
    testCreateExternalClampedUint8TypedData();
    testTypedDataRange(false);
    testUnsignedTypedDataRange(false);
    testClampedUnsignedTypedDataRange(false);
    testExternalClampedUnsignedTypedDataRange(false);
    testSetRange();
    testIndexOutOfRange();
    testIndexOf();
    testGetAtIndex();
    testSetAtIndex();
  }
  testTypedDataRange(true);
  testUnsignedTypedDataRange(true);
  testExternalClampedUnsignedTypedDataRange(true);
}

