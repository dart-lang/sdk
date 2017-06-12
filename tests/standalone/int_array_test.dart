// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native int arrays.

// Library tag to be able to run in html test framework.
library IntArrayTest;

import "package:expect/expect.dart";
import 'dart:typed_data';

void testInt16() {
  Int16List intArray = new Int16List(4);
  intArray[0] = 0;
  intArray[1] = -1;
  intArray[2] = -2;
  intArray[3] = -3;
  for (int i = 0; i < intArray.length; i++) {
    intArray[i]++;
  }
  var x = intArray[0];
  var y = intArray[1];
  var z = intArray[2];
  var w = intArray[3];
  Expect.equals(1, x);
  Expect.equals(0, y);
  Expect.equals(-1, z);
  Expect.equals(-2, w);
  var t = y + 1;
  intArray[0] = t;
  Expect.equals(t, intArray[0]);
}

void testUint16() {
  Uint16List intArray = new Uint16List(4);
  intArray[0] = 0;
  intArray[1] = 1;
  intArray[2] = 2;
  intArray[3] = 3;
  for (int i = 0; i < intArray.length; i++) {
    intArray[i]--;
  }
  var x = intArray[0];
  var y = intArray[1];
  var z = intArray[2];
  var w = intArray[3];
  Expect.equals(65535, x);
  Expect.equals(0, y);
  Expect.equals(1, z);
  Expect.equals(2, w);
  var t = y + 1;
  intArray[0] = t;
  Expect.equals(t, intArray[0]);
}

void testInt32ToSmi() {
  Int32List intArray;

  intArray = new Int32List(4);
  intArray[0] = 1073741823; // SmiMax
  intArray[1] = -1073741824; // SmiMin
  intArray[2] = 1073741824; // SmiMax+1
  intArray[3] = -1073741825; // SmiMin-1
  var x = intArray[0];
  var y = intArray[1];
  var z = intArray[2];
  var w = intArray[3];
  Expect.equals(1073741823, x);
  Expect.equals(-1073741824, y);
  Expect.equals(1073741824, z);
  Expect.equals(-1073741825, w);
}

void testUint32ToSmi() {
  Uint32List intArray;

  intArray = new Uint32List(4);
  intArray[0] = 1073741823; // SmiMax
  intArray[1] = -1; // 0xFFFFFFFF : 4294967295
  intArray[2] = 1073741830; // SmiMax+7
  intArray[3] = -1073741825; // 0xbfffffff : 3221225471
  var x = intArray[0];
  var y = intArray[1];
  var z = intArray[2];
  var w = intArray[3];
  Expect.equals(1073741823, x);
  Expect.equals(4294967295, y);
  Expect.equals(1073741830, z);
  Expect.equals(3221225471, w);
}

void testInt64ToSmi() {
  Int64List intArray;

  intArray = new Int64List(4);
  intArray[0] = 4611686018427387903; // SmiMax
  intArray[1] = -4611686018427387904; // SmiMin
  intArray[2] = 4611686018427387904; // SmiMax+1
  intArray[3] = -4611686018427387905; // SmiMin-1
  var x = intArray[0];
  var y = intArray[1];
  var z = intArray[2];
  var w = intArray[3];
  Expect.equals(4611686018427387903, x);
  Expect.equals(-4611686018427387904, y);
  Expect.equals(4611686018427387904, z);
  Expect.equals(-4611686018427387905, w);
}

void testUint64ToSmi() {
  Uint64List intArray;

  intArray = new Uint64List(4);
  intArray[0] = 4611686018427387903; // SmiMax
  intArray[1] = -1; // 0xFFFFFFFFFFFFFFFF : 18446744073709551615
  intArray[2] = 4611686018427387904; // SmiMax+1
  intArray[3] = 9223372036854775808;
  var x = intArray[0];
  var y = intArray[1];
  var z = intArray[2];
  var w = intArray[3];
  Expect.equals(4611686018427387903, x);
  Expect.equals(18446744073709551615, y);
  Expect.equals(4611686018427387904, z);
  Expect.equals(9223372036854775808, w);
}

main() {
  testUint64ToSmi();
  for (int i = 0; i < 2000; i++) {
    testInt16();
    testUint16();
    testInt32ToSmi();
    testUint32ToSmi();
    testInt64ToSmi();
    testUint64ToSmi();
  }
}
