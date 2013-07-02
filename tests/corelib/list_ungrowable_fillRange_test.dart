// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

import 'package:expect/expect.dart';
import 'dart:typed_data';

main() {
  testFloat32FillRange();
  testFloat64FillRange();
  testInt8FillRange();
  testInt16FillRange();
  testInt32FillRange();
  testUint8FillRange();
  testUint16FillRange();
  testUint32FillRange();
  testUint8ClampedFillRange();

}

void testFloat32FillRange() {
  Float32List list = new Float32List(4);
  list.fillRange(0, 4, 0.0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(0, 0, -6.0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(4, 4, 6.0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(1, 3, -6.0);
  Expect.listEquals([0, -6, -6, 0], list);
}

void testFloat64FillRange() {
  Float64List list = new Float64List(4);
  list.fillRange(0, 4, 0.0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(0, 0, -6.0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(4, 4, -6.0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(1, 3, -6.0);
  Expect.listEquals([0, -6, -6, 0], list);
}

void testInt8FillRange() {
  Int8List list = new Int8List(4);
  list.fillRange(0, 4, 0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(0, 0, -6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(4, 4, 6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(1, 3, -6);
  Expect.listEquals([0, -6, -6, 0], list);
}

void testInt16FillRange() {
  Int16List list = new Int16List(4);
  list.fillRange(0, 4, 0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(0, 0, -6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(4, 4, -6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(1, 3, -6);
  Expect.listEquals([0, -6, -6, 0], list);
}

void testInt32FillRange() {
  Int32List list = new Int32List(4);
  list.fillRange(0, 4, 0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(0, 0, -6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(4, 4, -6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(1, 3, -6);
  Expect.listEquals([0, -6, -6, 0], list);
}

void testUint8FillRange() {
  Uint8List list = new Uint8List(4);
  list.fillRange(0, 4, 0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(0, 0, 6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(4, 4, 6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(1, 3, 6);
  Expect.listEquals([0, 6, 6, 0], list);
}

void testUint16FillRange() {
  Uint16List list = new Uint16List(4);
  list.fillRange(0, 4, 0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(0, 0, 6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(4, 4, 6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(1, 3, 6);
  Expect.listEquals([0, 6, 6, 0], list);
}

void testUint32FillRange() {
  Uint32List list = new Uint32List(4);
  list.fillRange(0, 4, 0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(0, 0, 6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(4, 4, 6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(1, 3, 6);
  Expect.listEquals([0, 6, 6, 0], list);
}

void testUint8ClampedFillRange() {
  Uint8ClampedList list = new Uint8ClampedList(4);
  list.fillRange(0, 4, 0);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(0, 0, 6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(4, 4, 6);
  Expect.listEquals([0, 0, 0, 0], list);
  list.fillRange(1, 3, 6);
  Expect.listEquals([0, 6, 6, 0], list);
}
