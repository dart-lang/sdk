// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

// Library tag to be able to run in html test framework.
library typed_data_hierarchy_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

var inscrutable = null;

void implementsTypedData() {
  Expect.isTrue(inscrutable(new ByteData(1)) is TypedData);
  Expect.isTrue(inscrutable(new Float32List(1)) is TypedData);
  Expect.isTrue(inscrutable(new Float32x4List(1)) is TypedData);
  Expect.isTrue(inscrutable(new Float64List(1)) is TypedData);
  Expect.isTrue(inscrutable(new Int8List(1)) is TypedData);
  Expect.isTrue(inscrutable(new Int16List(1)) is TypedData);
  Expect.isTrue(inscrutable(new Int32List(1)) is TypedData);
  Expect.isTrue(inscrutable(new Uint8List(1)) is TypedData);
  Expect.isTrue(inscrutable(new Uint8ClampedList(1)) is TypedData);
  Expect.isTrue(inscrutable(new Uint16List(1)) is TypedData);
  Expect.isTrue(inscrutable(new Uint32List(1)) is TypedData);
}


void implementsList() {
  Expect.isTrue(inscrutable(new Float32List(1)) is List<double>);
  Expect.isTrue(inscrutable(new Float32x4List(1)) is List<Float32x4>);
  Expect.isTrue(inscrutable(new Float64List(1)) is List<double>);
  Expect.isTrue(inscrutable(new Int8List(1)) is List<int>);
  Expect.isTrue(inscrutable(new Int16List(1)) is List<int>);
  Expect.isTrue(inscrutable(new Int32List(1)) is List<int>);
  Expect.isTrue(inscrutable(new Uint8List(1)) is List<int>);
  Expect.isTrue(inscrutable(new Uint8ClampedList(1)) is List<int>);
  Expect.isTrue(inscrutable(new Uint16List(1)) is List<int>);
  Expect.isTrue(inscrutable(new Uint32List(1)) is List<int>);
}

testClampedList() {
  Expect.isFalse(inscrutable(new Uint8ClampedList(1)) is Uint8List);
}

main() {
  inscrutable = (x) => x;
  implementsTypedData();
  implementsList();
  testClampedList();
}

