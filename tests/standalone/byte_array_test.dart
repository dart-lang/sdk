// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native byte arrays.

// Library tag to be able to run in html test framework.
library ByteArrayTest;

import 'dart:scalarlist';

void testCreateUint8ByteArray() {
  Uint8List byteArray;

  byteArray = new Uint8List(0);
  Expect.isTrue(byteArray is Uint8List);
  Expect.isFalse(byteArray is Uint8ClampedList);
  Expect.equals(0, byteArray.length);

  byteArray = new Uint8List(10);
  Expect.equals(10, byteArray.length);
  for (int i = 0; i < 10; i++) {
    Expect.equals(0, byteArray[i]);
  }
}

void testCreateClampedUint8ByteArray() {
  Uint8ClampedList clampedByteArray;

  clampedByteArray = new Uint8ClampedList(0);
  Expect.isTrue(clampedByteArray is Uint8ClampedList);
  Expect.isFalse(clampedByteArray is Uint8List);
  Expect.equals(0, clampedByteArray.length);
  Expect.equals(0, clampedByteArray.lengthInBytes());

  clampedByteArray = new Uint8ClampedList(10);
  Expect.equals(10, clampedByteArray.length);
  for (int i = 0; i < 10; i++) {
    Expect.equals(0, clampedByteArray[i]);
  }
}

void testCreateExternalClampedUint8ByteArray() {
  List externalClampedByteArray;

  externalClampedByteArray = new Uint8ClampedList.transferable(0);
  Expect.isTrue(externalClampedByteArray is Uint8ClampedList);
  Expect.isFalse(externalClampedByteArray is Uint8List);
  Expect.equals(0, externalClampedByteArray.length);
  Expect.equals(0, externalClampedByteArray.lengthInBytes());

  externalClampedByteArray = new Uint8ClampedList.transferable(10);
  Expect.equals(10, externalClampedByteArray.length);
  for (int i = 0; i < 10; i++) {
    Expect.equals(0, externalClampedByteArray[i]);
  }

}

void testUnsignedByteArrayRange(bool check_throws) {
  Uint8List byteArray;
  byteArray = new Uint8List(10);

  byteArray[1] = 255;
  Expect.equals(255, byteArray[1]);
  byteArray[1] = 0;
  Expect.equals(0, byteArray[1]);

  for (int i = 0; i < byteArray.length; i++) {
    byteArray[i] = i;
  }
  for (int i = 0; i < byteArray.length; i++) {
    Expect.equals(i, byteArray[i]);
  }

  // These should eventually throw.
  byteArray[1] = 256;
  byteArray[1] = -1;
  byteArray[2] = -129;
  if (check_throws) {
    Expect.throws(() {
      byteArray[1] = 1.2;
    });
  }
}

void testClampedUnsignedByteArrayRangeHelper(Uint8ClampedList byteArray,
                                             bool check_throws) {
  Uint8ClampedList byteArray;
  byteArray = new Uint8ClampedList(10);

  byteArray[1] = 255;
  Expect.equals(255, byteArray[1]);
  byteArray[1] = 0;
  Expect.equals(0, byteArray[1]);
  for (int i = 0; i < byteArray.length; i++) {
    byteArray[i] = i;
  }
  for (int i = 0; i < byteArray.length; i++) {
    Expect.equals(i, byteArray[i]);
  }

  // These should eventually throw.
  byteArray[1] = 256;
  byteArray[2] = -129;
  Expect.equals(255, byteArray[1]);
  Expect.equals(0, byteArray[2]);
}

void testClampedUnsignedByteArrayRange(bool check_throws) {
  testClampedUnsignedByteArrayRangeHelper(new Uint8ClampedList(10),
                                          check_throws);
}


void testExternalClampedUnsignedByteArrayRange(bool check_throws) {
  testClampedUnsignedByteArrayRangeHelper(new Uint8ClampedList.transferable(10),
                                          check_throws);
}


void testByteArrayRange(bool check_throws) {
  Int8List byteArray;
  byteArray = new Int8List(10);
  byteArray[1] = 0;
  Expect.equals(0, byteArray[1]);
  byteArray[2] = -128;
  Expect.equals(-128, byteArray[2]);
  byteArray[3] = 127;
  Expect.equals(127, byteArray[3]);
  // This should eventually throw.
  byteArray[0] = 128;
  byteArray[4] = -129;
  if (check_throws) {
    Expect.throws(() {
      byteArray[1] = 1.2;
    });
  }
}

void testSetRangeHelper(byteArray) {
  List<int> list = [10, 11, 12];
  byteArray.setRange(0, 3, list);
  for (int i = 0; i < 3; i++) {
    Expect.equals(10 + i, byteArray[i]);
  }

  byteArray[0] = 20;
  byteArray[1] = 21;
  byteArray[2] = 22;
  list.setRange(0, 3, byteArray);
  for (int i = 0; i < 3; i++) {
    Expect.equals(20 + i, list[i]);
  }

  byteArray.setRange(1, 2, const [8, 9]);
  Expect.equals(20, byteArray[0]);
  Expect.equals(8, byteArray[1]);
  Expect.equals(9, byteArray[2]);
}

void testSetRange() {
  testSetRangeHelper(new Uint8List(3));
  testSetRangeHelper(new Uint8List.transferable(3));
  testSetRangeHelper(new Uint8ClampedList(3));
  testSetRangeHelper(new Uint8ClampedList.transferable(3));
}

void testIndexOutOfRangeHelper(byteArray) {
  List<int> list = const [0, 1, 2, 3];

  Expect.throws(() {
    byteArray.setRange(0, 4, list);
  });

  Expect.throws(() {
    byteArray.setRange(3, 1, list);
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

void testSubArrayHelper(list) {
  var array = list.asByteArray();
  Expect.equals(0, array.subByteArray(0, 0).lengthInBytes());
  Expect.equals(0, array.subByteArray(5, 0).lengthInBytes());
  Expect.equals(0, array.subByteArray(10, 0).lengthInBytes());
  Expect.equals(0, array.subByteArray(10).lengthInBytes());
  Expect.equals(0, array.subByteArray(10, null).lengthInBytes());
  Expect.equals(5, array.subByteArray(0, 5).lengthInBytes());
  Expect.equals(5, array.subByteArray(5, 5).lengthInBytes());
  Expect.equals(5, array.subByteArray(5).lengthInBytes());
  Expect.equals(5, array.subByteArray(5, null).lengthInBytes());
  Expect.equals(10, array.subByteArray(0, 10).lengthInBytes());
  Expect.equals(10, array.subByteArray(0).lengthInBytes());
  Expect.equals(10, array.subByteArray(0, null).lengthInBytes());
  Expect.equals(10, array.subByteArray().lengthInBytes());
  testThrowsIndex(function) {
    Expect.throws(function, (e) => e is RangeError);
  }
  testThrowsIndex(() => array.subByteArray(0, -1));
  testThrowsIndex(() => array.subByteArray(1, -1));
  testThrowsIndex(() => array.subByteArray(10, -1));
  testThrowsIndex(() => array.subByteArray(-1, 0));
  testThrowsIndex(() => array.subByteArray(-1));
  testThrowsIndex(() => array.subByteArray(-1, null));
  testThrowsIndex(() => array.subByteArray(11, 0));
  testThrowsIndex(() => array.subByteArray(11));
  testThrowsIndex(() => array.subByteArray(11, null));
  testThrowsIndex(() => array.subByteArray(6, 5));

  bool checkedMode = false;
  assert(checkedMode = true);
  if (!checkedMode) {
    // In checked mode these will necessarily throw a TypeError.
    Expect.throws(() => array.subByteArray(0, "5"), (e) => e is ArgumentError);
    Expect.throws(() => array.subByteArray("0", 5), (e) => e is ArgumentError);
    Expect.throws(() => array.subByteArray("0"), (e) => e is ArgumentError);
  }
  Expect.throws(() => array.subByteArray(null), (e) => e is ArgumentError);
}


void testSubArray() {
  testSubArrayHelper(new Uint8List(10));
  testSubArrayHelper(new Uint8List.transferable(10));
  testSubArrayHelper(new Uint8ClampedList(10));
  testSubArrayHelper(new Uint8ClampedList.transferable(10));
}

main() {
  for (int i = 0; i < 2000; i++) {
    testCreateUint8ByteArray();
    testCreateClampedUint8ByteArray();
    testCreateExternalClampedUint8ByteArray();
    testByteArrayRange(false);
    testUnsignedByteArrayRange(false);
    testClampedUnsignedByteArrayRange(false);
    testExternalClampedUnsignedByteArrayRange(false);
    testSetRange();
    testIndexOutOfRange();
    testIndexOf();
    testSubArray();
  }
  testByteArrayRange(true);
  testUnsignedByteArrayRange(true);
  testExternalClampedUnsignedByteArrayRange(true);
}

