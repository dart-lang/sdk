// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--deoptimization_counter_threshold=1000 --optimization-counter-threshold=10

// Library tag to be able to run in html test framework.
library float32x4_list_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

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
    // non-Float32x4 value.
    testLoadStoreDeopt(list, 0, 4.toDouble());
  } catch (_) {}
  for (int i = 0; i < 20; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // non-Float32x4List list.
    testLoadStoreDeopt([new Float32x4(2.0, 3.0, 4.0, 5.0)], 0, value);
  } catch (_) {}
  for (int i = 0; i < 20; i++) {
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

testSublist(array) {
  Expect.equals(8, array.length);
  Expect.isTrue(array is Float32x4List);
  var a = array.sublist(0, 1);
  Expect.equals(1, a.length);
  Expect.equals(0.0, a[0].x);
  Expect.equals(1.0, a[0].y);
  Expect.equals(2.0, a[0].z);
  Expect.equals(3.0, a[0].w);
  a = array.sublist(1, 2);
  Expect.equals(4.0, a[0].x);
  Expect.equals(5.0, a[0].y);
  Expect.equals(6.0, a[0].z);
  Expect.equals(7.0, a[0].w);
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
  /// Same as Expect.identical, but also works with NaNs and -0.0 for dart2js.
  void checkEquals(expected, actual) {
    if (expected.isNaN) {
      Expect.isTrue(actual.isNaN);
    } else if (expected == 0.0 && expected.isNegative) {
      Expect.isTrue(actual == 0.0 && actual.isNegative);
    } else {
      Expect.equals(expected, actual);
    }
  }

  var pairs = [
    [0.0, 0.0],
    [5e-324, 0.0],
    [2.225073858507201e-308, 0.0],
    [2.2250738585072014e-308, 0.0],
    [0.9999999999999999, 1.0],
    [1.0, 1.0],
    [1.0000000000000002, 1.0],
    [4294967295.0, 4294967296.0],
    [4294967296.0, 4294967296.0],
    [4503599627370495.5, 4503599627370496.0],
    [9007199254740992.0, 9007199254740992.0],
    [1.7976931348623157e+308, double.INFINITY],
    [0.49999999999999994, 0.5],
    [4503599627370497.0, 4503599627370496.0],
    [9007199254740991.0, 9007199254740992.0],
    [double.INFINITY, double.INFINITY],
    [double.NAN, double.NAN],
  ];

  var conserved = [
    1.401298464324817e-45,
    1.1754942106924411e-38,
    1.1754943508222875e-38,
    0.9999999403953552,
    1.0000001192092896,
    8388607.5,
    8388608.0,
    3.4028234663852886e+38,
    8388609.0,
    16777215.0,
  ];

  var minusPairs = pairs.map((pair) {
    return [-pair[0], -pair[1]];
  });
  var conservedPairs = conserved.map((value) => [value, value]);

  var allTests = [pairs, minusPairs, conservedPairs].expand((x) => x);

  for (var pair in allTests) {
    var input = pair[0];
    var expected = pair[1];
    var f;
    f = new Float32x4(input, 2.0, 3.0, 4.0);
    array[0] = f;
    f = array[0];
    checkEquals(expected, f.x);
    Expect.equals(2.0, f.y);
    Expect.equals(3.0, f.z);
    Expect.equals(4.0, f.w);

    f = new Float32x4(1.0, input, 3.0, 4.0);
    array[1] = f;
    f = array[1];
    Expect.equals(1.0, f.x);
    checkEquals(expected, f.y);
    Expect.equals(3.0, f.z);
    Expect.equals(4.0, f.w);

    f = new Float32x4(1.0, 2.0, input, 4.0);
    array[2] = f;
    f = array[2];
    Expect.equals(1.0, f.x);
    Expect.equals(2.0, f.y);
    checkEquals(expected, f.z);
    Expect.equals(4.0, f.w);

    f = new Float32x4(1.0, 2.0, 3.0, input);
    array[3] = f;
    f = array[3];
    Expect.equals(1.0, f.x);
    Expect.equals(2.0, f.y);
    Expect.equals(3.0, f.z);
    checkEquals(expected, f.w);
  }
}

main() {
  var list;

  list = new Float32x4List(8);
  for (int i = 0; i < 20; i++) {
    testLoadStore(list);
  }

  Float32List floatList = new Float32List(32);
  for (int i = 0; i < floatList.length; i++) {
    floatList[i] = i.toDouble();
  }
  list = new Float32x4List.view(floatList.buffer);
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
