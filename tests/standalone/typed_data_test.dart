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
  testIndexOfHelper(new Uint8List(10));
  testIndexOfHelper(new Uint8List.transferable(10));
  testIndexOfHelper(new Uint8ClampedList(10));
  testIndexOfHelper(new Uint8ClampedList.transferable(10));
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
  }
  testTypedDataRange(true);
  testUnsignedTypedDataRange(true);
  testExternalClampedUnsignedTypedDataRange(true);
}

