// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--deoptimization_counter_threshold=1000 --optimization-counter-threshold=10

// Library tag to be able to run in html test framework.
library int32x4_list_test;

import 'package:expect/expect.dart';
import 'dart:typed_data';

testLoadStore(array) {
  Expect.equals(8, array.length);
  Expect.isTrue(array is List<Int32x4>);
  array[0] = new Int32x4(1, 2, 3, 4);
  Expect.equals(1, array[0].x);
  Expect.equals(2, array[0].y);
  Expect.equals(3, array[0].z);
  Expect.equals(4, array[0].w);
  array[1] = array[0];
  array[0] = array[0].withX(9);
  Expect.equals(9, array[0].x);
  Expect.equals(2, array[0].y);
  Expect.equals(3, array[0].z);
  Expect.equals(4, array[0].w);
  Expect.equals(1, array[1].x);
  Expect.equals(2, array[1].y);
  Expect.equals(3, array[1].z);
  Expect.equals(4, array[1].w);
}

testLoadStoreDeopt(array, index, value) {
  array[index] = value;
  Expect.equals(value.x, array[index].x);
  Expect.equals(value.y, array[index].y);
  Expect.equals(value.z, array[index].z);
  Expect.equals(value.w, array[index].w);
}

testLoadStoreDeoptDriver() {
  Int32x4List list = new Int32x4List(4);
  Int32x4 value = new Int32x4(1, 2, 3, 4);
  for (int i = 0; i < 20; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // Invalid index.
    testLoadStoreDeopt(list, 5, value);
  } catch (_) {}
  for (int i = 0; i < 20; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // null list.
    testLoadStoreDeopt(null, 0, value);
  } catch (_) {}
  for (int i = 0; i < 20; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // null value.
    testLoadStoreDeopt(list, 0, null);
  } catch (_) {}
  for (int i = 0; i < 20; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // non-smi index.
    testLoadStoreDeopt(list, 3.14159, value);
  } catch (_) {}
  for (int i = 0; i < 20; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // non-Int32x4 value.
    testLoadStoreDeopt(list, 0, 4.toDouble());
  } catch (_) {}
  for (int i = 0; i < 20; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // non-Int32x4List list.
    testLoadStoreDeopt([new Int32x4(2, 3, 4, 5)], 0, value);
  } catch (_) {}
  for (int i = 0; i < 20; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
}

testListZero() {
  Int32x4List list = new Int32x4List(1);
  Expect.equals(0, list[0].x);
  Expect.equals(0, list[0].y);
  Expect.equals(0, list[0].z);
  Expect.equals(0, list[0].w);
}

testView(array) {
  Expect.equals(8, array.length);
  Expect.isTrue(array is List<Int32x4>);
  Expect.equals(0, array[0].x);
  Expect.equals(1, array[0].y);
  Expect.equals(2, array[0].z);
  Expect.equals(3, array[0].w);
  Expect.equals(4, array[1].x);
  Expect.equals(5, array[1].y);
  Expect.equals(6, array[1].z);
  Expect.equals(7, array[1].w);
}

testSublist(array) {
  Expect.equals(8, array.length);
  Expect.isTrue(array is Int32x4List);
  var a = array.sublist(0, 1);
  Expect.equals(1, a.length);
  Expect.equals(0, a[0].x);
  Expect.equals(1, a[0].y);
  Expect.equals(2, a[0].z);
  Expect.equals(3, a[0].w);
  a = array.sublist(1, 2);
  Expect.equals(4, a[0].x);
  Expect.equals(5, a[0].y);
  Expect.equals(6, a[0].z);
  Expect.equals(7, a[0].w);
  a = array.sublist(0);
  Expect.equals(a.length, array.length);
  for (int i = 0; i < array.length; i++) {
    Expect.equals(array[i].x, a[i].x);
    Expect.equals(array[i].y, a[i].y);
    Expect.equals(array[i].z, a[i].z);
    Expect.equals(array[i].w, a[i].w);
  }
}

void testSpecialValues(array) {
  var tests = [
    [0x8901234567890, 0x34567890],
    [0x89012A4567890, -1537836912],
    [0x80000000, -2147483648],
    [-0x80000000, -2147483648],
    [0x7fffffff, 2147483647],
    [-0x7fffffff, -2147483647],
  ];
  var int32x4;

  for (var test in tests) {
    var input = test[0];
    var expected = test[1];

    int32x4 = new Int32x4(input, 2, 3, 4);
    array[0] = int32x4;
    int32x4 = array[0];
    Expect.equals(expected, int32x4.x);
    Expect.equals(2, int32x4.y);
    Expect.equals(3, int32x4.z);
    Expect.equals(4, int32x4.w);

    int32x4 = new Int32x4(1, input, 3, 4);
    array[0] = int32x4;
    int32x4 = array[0];
    Expect.equals(1, int32x4.x);
    Expect.equals(expected, int32x4.y);
    Expect.equals(3, int32x4.z);
    Expect.equals(4, int32x4.w);

    int32x4 = new Int32x4(1, 2, input, 4);
    array[0] = int32x4;
    int32x4 = array[0];
    Expect.equals(1, int32x4.x);
    Expect.equals(2, int32x4.y);
    Expect.equals(expected, int32x4.z);
    Expect.equals(4, int32x4.w);

    int32x4 = new Int32x4(1, 2, 3, input);
    array[0] = int32x4;
    int32x4 = array[0];
    Expect.equals(1, int32x4.x);
    Expect.equals(2, int32x4.y);
    Expect.equals(3, int32x4.z);
    Expect.equals(expected, int32x4.w);
  }
}

main() {
  var list;

  list = new Int32x4List(8);
  for (int i = 0; i < 20; i++) {
    testLoadStore(list);
  }
  for (int i = 0; i < 20; i++) {
    testSpecialValues(list);
  }

  Uint32List uint32List = new Uint32List(32);
  for (int i = 0; i < uint32List.length; i++) {
    uint32List[i] = i;
  }
  list = new Int32x4List.view(uint32List.buffer);
  for (int i = 0; i < 20; i++) {
    testView(list);
  }
  for (int i = 0; i < 20; i++) {
    testSublist(list);
  }
  for (int i = 0; i < 20; i++) {
    testLoadStore(list);
  }
  for (int i = 0; i < 20; i++) {
    testListZero();
  }
  for (int i = 0; i < 20; i++) {
    testSpecialValues(list);
  }
  testLoadStoreDeoptDriver();
}
