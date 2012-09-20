// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native byte arrays.

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

main() {
  for (int i = 0; i < 2000; i++) {
    testCreateByteArray();
    testSetRange();
    testIndexOutOfRange();
    testIndexOf();
  }
}
