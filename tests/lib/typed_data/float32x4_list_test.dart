// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background_compilation

import 'dart:typed_data';

import 'package:expect/expect.dart';

void testLoadStore(Float32x4List array) {
  Expect.equals(8, array.length);
  array[0] = Float32x4(1.0, 2.0, 3.0, 4.0);
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

void testSwap(Float32x4List array) {
  array[0] = Float32x4(1.0, 2.0, 3.0, 4.0);
  array[1] = Float32x4(5.0, 6.0, 7.0, 8.0);
  for (int i = 0; i < 41; i++) {
    final a = array[0];
    final b = array[1];
    array[0] = b;
    array[1] = a;
  }
  Expect.equals(5.0, array[0].x);
  Expect.equals(8.0, array[0].w);
  Expect.equals(1.0, array[1].x);
  Expect.equals(4.0, array[1].w);
}

void testLoadStoreDeopt(dynamic array, dynamic index, dynamic value) {
  array[index] = value;
  Expect.equals(value.x, array[index].x);
  Expect.equals(value.y, array[index].y);
  Expect.equals(value.z, array[index].z);
  Expect.equals(value.w, array[index].w);
}

void testLoadStoreDeoptDriver() {
  final list = Float32x4List(4);
  final value = Float32x4(1.0, 2.0, 3.0, 4.0);
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
    testLoadStoreDeopt([Float32x4(2.0, 3.0, 4.0, 5.0)], 0, value);
  } catch (_) {}
  for (int i = 0; i < 20; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
}

void testListZero() {
  final list = Float32x4List(1);
  Expect.equals(0.0, list[0].x);
  Expect.equals(0.0, list[0].y);
  Expect.equals(0.0, list[0].z);
  Expect.equals(0.0, list[0].w);
}

void testView(Float32x4List array) {
  Expect.equals(8, array.length);
  Expect.equals(0.0, array[0].x);
  Expect.equals(1.0, array[0].y);
  Expect.equals(2.0, array[0].z);
  Expect.equals(3.0, array[0].w);
  Expect.equals(4.0, array[1].x);
  Expect.equals(5.0, array[1].y);
  Expect.equals(6.0, array[1].z);
  Expect.equals(7.0, array[1].w);
}

void testSublist(Float32x4List array) {
  Expect.equals(8, array.length);
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

void testSpecialValues(Float32x4List array) {
  /// Same as Expect.identical, but also works with NaNs and -0.0 for dart2js.
  void checkEquals(double expected, double actual) {
    if (expected.isNaN) {
      Expect.isTrue(actual.isNaN);
    } else if (expected == 0.0 && expected.isNegative) {
      Expect.isTrue(actual == 0.0 && actual.isNegative);
    } else {
      Expect.equals(expected, actual);
    }
  }

  final pairs = [
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
    [1.7976931348623157e+308, double.infinity],
    [0.49999999999999994, 0.5],
    [4503599627370497.0, 4503599627370496.0],
    [9007199254740991.0, 9007199254740992.0],
    [double.infinity, double.infinity],
    [double.nan, double.nan],
  ];

  final conserved = [
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

  final minusPairs = pairs.map((pair) => [-pair[0], -pair[1]]);
  final conservedPairs = conserved.map((value) => [value, value]);
  final allTests = [pairs, minusPairs, conservedPairs].expand((x) => x);

  for (final pair in allTests) {
    final input = pair[0];
    final expected = pair[1];
    var f = Float32x4(input, 2.0, 3.0, 4.0);
    array[0] = f;
    f = array[0];
    checkEquals(expected, f.x);
    Expect.equals(2.0, f.y);
    Expect.equals(3.0, f.z);
    Expect.equals(4.0, f.w);

    f = Float32x4(1.0, input, 3.0, 4.0);
    array[1] = f;
    f = array[1];
    Expect.equals(1.0, f.x);
    checkEquals(expected, f.y);
    Expect.equals(3.0, f.z);
    Expect.equals(4.0, f.w);

    f = Float32x4(1.0, 2.0, input, 4.0);
    array[2] = f;
    f = array[2];
    Expect.equals(1.0, f.x);
    Expect.equals(2.0, f.y);
    checkEquals(expected, f.z);
    Expect.equals(4.0, f.w);

    f = Float32x4(1.0, 2.0, 3.0, input);
    array[3] = f;
    f = array[3];
    Expect.equals(1.0, f.x);
    Expect.equals(2.0, f.y);
    Expect.equals(3.0, f.z);
    checkEquals(expected, f.w);
  }
}

void main() {
  final list = Float32x4List(8);
  for (int i = 0; i < 20; i++) {
    testLoadStore(list);
  }
  for (int i = 0; i < 20; i++) {
    testSwap(list);
  }

  final floatList = Float32List(32);
  for (int i = 0; i < floatList.length; i++) {
    floatList[i] = i.toDouble();
  }
  final view = Float32x4List.view(floatList.buffer);
  for (int i = 0; i < 20; i++) {
    testView(view);
  }
  for (int i = 0; i < 20; i++) {
    testSublist(view);
  }
  for (int i = 0; i < 20; i++) {
    testLoadStore(view);
  }
  for (int i = 0; i < 20; i++) {
    testListZero();
  }
  for (int i = 0; i < 20; i++) {
    testSpecialValues(view);
  }
  testLoadStoreDeoptDriver();
}
