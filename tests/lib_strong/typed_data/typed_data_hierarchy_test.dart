// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

// Library tag to be able to run in html test framework.
library typed_data_hierarchy_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

var inscrutable = null;

void testClampedList() {
  // Force lookup of Uint8List first.
  Expect.isTrue(inscrutable(new Uint8List(1)) is Uint8List);

  Expect.isFalse(
      new Uint8ClampedList(1) is Uint8List,
      'Uint8ClampedList should not be a subtype of Uint8List '
      'in optimizable test');
  Expect.isFalse(inscrutable(new Uint8ClampedList(1)) is Uint8List,
      'Uint8ClampedList should not be a subtype of Uint8List in dynamic test');
}

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

main() {
  inscrutable = (x) => x;

  // Note: this test must come first to control order of lookup on Uint8List and
  // Uint8ClampedList.
  testClampedList();

  implementsTypedData();
  implementsList();
}
