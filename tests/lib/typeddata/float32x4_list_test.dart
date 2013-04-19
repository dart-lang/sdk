// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--deoptimization_counter_threshold=1000

// Library tag to be able to run in html test framework.
library float32x4_list_test;

import 'package:expect/expect.dart';
import 'dart:typeddata';

testLoadStore(array) {
  Expect.equals(8, array.length);
  Expect.isTrue(array is List<Float32x4>);
  array[0] = new Float32x4(1.0, 2.0, 3.0, 4.0);
  Expect.equals(1.0, array[0].x);
  Expect.equals(2.0, array[0].y);
  Expect.equals(3.0, array[0].z);
  Expect.equals(4.0, array[0].w);
  array[1] = array[0];
  array[0] = array[0].withX(9.0);
  Expect.equals(9.0, array[0].x);
  Expect.equals(2.0, array[0].y);
  Expect.equals(3.0, array[0].z);
  Expect.equals(4.0, array[0].w);
  Expect.equals(1.0, array[1].x);
  Expect.equals(2.0, array[1].y);
  Expect.equals(3.0, array[1].z);
  Expect.equals(4.0, array[1].w);
}

testLoadStoreDeopt(array, index, value) {
  array[index] = value;
  Expect.equals(value.x, array[index].x);
  Expect.equals(value.y, array[index].y);
  Expect.equals(value.z, array[index].z);
  Expect.equals(value.w, array[index].w);
}

testLoadStoreDeoptDriver() {
  Float32x4List list = new Float32x4List(4);
  Float32x4 value = new Float32x4(1.0, 2.0, 3.0, 4.0);
  for (int i = 0; i < 3000; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // Invalid index.
    testLoadStoreDeopt(list, 5, value);
  } catch (_) {}
  for (int i = 0; i < 3000; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // null list.
    testLoadStoreDeopt(null, 0, value);
  } catch (_) {}
  for (int i = 0; i < 3000; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // null value.
    testLoadStoreDeopt(list, 0, null);
  } catch (_) {}
  for (int i = 0; i < 3000; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // non-smi index.
    testLoadStoreDeopt(list, 3.14159, value);
  } catch (_) {}
  for (int i = 0; i < 3000; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // non-Float32x4 value.
    testLoadStoreDeopt(list, 0, 4.toDouble());
  } catch (_) {}
  for (int i = 0; i < 3000; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // non-Float32x4List list.
    testLoadStoreDeopt([new Float32x4(2.0, 3.0, 4.0, 5.0)], 0, value);
  } catch (_) {}
  for (int i = 0; i < 3000; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
}

testListZero() {
  Float32x4List list = new Float32x4List(1);
  Expect.equals(0.0, list[0].x);
  Expect.equals(0.0, list[0].y);
  Expect.equals(0.0, list[0].z);
  Expect.equals(0.0, list[0].w);
}

testView(array) {
  Expect.equals(8, array.length);
  Expect.isTrue(array is List<Float32x4>);
  Expect.equals(0.0, array[0].x);
  Expect.equals(1.0, array[0].y);
  Expect.equals(2.0, array[0].z);
  Expect.equals(3.0, array[0].w);
  Expect.equals(4.0, array[1].x);
  Expect.equals(5.0, array[1].y);
  Expect.equals(6.0, array[1].z);
  Expect.equals(7.0, array[1].w);
}

main() {
  var list;

  list = new Float32x4List(8);
  for (int i = 0; i < 3000; i++) {
    testLoadStore(list);
  }

  Float32List floatList = new Float32List(32);
  for (int i = 0; i < floatList.length; i++) {
    floatList[i] = i.toDouble();
  }
  list = new Float32x4List.view(floatList);
  for (int i = 0; i < 3000; i++) {
    testView(list);
  }
  for (int i = 0; i < 3000; i++) {
    testLoadStore(list);
  }
  for (int i = 0; i < 3000; i++) {
    testListZero();
  }
  testLoadStoreDeoptDriver();
}
