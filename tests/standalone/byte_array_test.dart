// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native byte arrays.

// Library tag to be able to run in html test framework.
#library("ByteArrayTest.dart");

#import('dart:scalarlist');

void testCreateByteArray() {
  Uint8List byteArray;

  byteArray = new Uint8List(0);
  Expect.equals(0, byteArray.length);

  byteArray = new Uint8List(10);
  Expect.equals(10, byteArray.length);
  for (int i = 0; i < 10; i++) {
    Expect.equals(0, byteArray[i]);
  }

}

void testUnsignedByteArrayRange(bool check_throws) {
  Uint8List byteArray;
  byteArray = new Uint8List(10);

  byteArray[1] = 255;
  Expect.equals(255, byteArray[1]);
  byteArray[1] = 0;
  Expect.equals(0, byteArray[1]);

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

void testSetRange() {
  Uint8List byteArray = new Uint8List(3);

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

void testIndexOutOfRange() {
  Uint8List byteArray = new Uint8List(3);
  List<int> list = const [0, 1, 2, 3];

  Expect.throws(() {
    byteArray.setRange(0, 4, list);
  });

  Expect.throws(() {
    byteArray.setRange(3, 1, list);
  });
}

void testIndexOf() {
  var list = new Uint8List(10);
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

void testSubArray() {
  var list = new Uint8List(10);
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

main() {
  for (int i = 0; i < 2000; i++) {
    testCreateByteArray();
    testByteArrayRange(false);
    testUnsignedByteArrayRange(false);
    testSetRange();
    testIndexOutOfRange();
    testIndexOf();
    testSubArray();
  }
  testByteArrayRange(true);
  testUnsignedByteArrayRange(true);
}

