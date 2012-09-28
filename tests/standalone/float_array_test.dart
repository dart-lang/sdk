// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native float arrays.

// Library tag to be able to run in html test framework.
#library("FloatArrayTest.dart");

#import('dart:scalarlist');

void testCreateFloatArray() {
  Float32List floatArray;

  floatArray = new Float32List(0);
  Expect.equals(0, floatArray.length);

  floatArray = new Float32List(10);
  Expect.equals(10, floatArray.length);
  for (int i = 0; i < 10; i++) {
    Expect.equals(0.0, floatArray[i]);
  }
}

void testSetRange() {
  Float32List floatArray = new Float32List(3);

  List<num> list = [10.0, 11.0, 12.0];
  floatArray.setRange(0, 3, list);
  for (int i = 0; i < 3; i++) {
    Expect.equals(10 + i, floatArray[i]);
  }

  floatArray[0] = 20.0;
  floatArray[1] = 21.0;
  floatArray[2] = 22.0;
  list.setRange(0, 3, floatArray);
  for (int i = 0; i < 3; i++) {
    Expect.equals(20 + i, list[i]);
  }

  floatArray.setRange(1, 2, const [8.0, 9.0]);
  Expect.equals(20, floatArray[0]);
  Expect.equals(8, floatArray[1]);
  Expect.equals(9, floatArray[2]);
}

void testIndexOutOfRange() {
  Float32List floatArray = new Float32List(3);
  List<num> list = const [0.0, 1.0, 2.0, 3.0];

  Expect.throws(() {
    floatArray.setRange(0, 4, list);
  });

  Expect.throws(() {
    floatArray.setRange(3, 1, list);
  });
}

void testIndexOf() {
  var list = new Float32List(10);
  for (int i = 0; i < list.length; i++) {
    list[i] = i + 10.0;
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
    testCreateFloatArray();
    testSetRange();
    testIndexOutOfRange();
    testIndexOf();
  }
}
