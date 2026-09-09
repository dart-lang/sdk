// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background_compilation

import 'dart:typed_data';

import 'package:expect/expect.dart';

void testLoadStore(Float64x2List array) {
  Expect.equals(8, array.length);
  array[0] = Float64x2(1.0, 2.0);
  Expect.equals(1.0, array[0].x);
  Expect.equals(2.0, array[0].y);
  array[1] = array[0];
  array[0] = array[0].withX(9.0);
  Expect.equals(9.0, array[0].x);
  Expect.equals(2.0, array[0].y);
  Expect.equals(1.0, array[1].x);
  Expect.equals(2.0, array[1].y);
}

void testSwap(Float64x2List array) {
  array[0] = Float64x2(1.0, 2.0);
  array[1] = Float64x2(3.0, 4.0);
  for (int i = 0; i < 41; i++) {
    final a = array[0];
    final b = array[1];
    array[0] = b;
    array[1] = a;
  }
  Expect.equals(3.0, array[0].x);
  Expect.equals(4.0, array[0].y);
  Expect.equals(1.0, array[1].x);
  Expect.equals(2.0, array[1].y);
}

void testLoadStoreDeopt(dynamic array, dynamic index, dynamic value) {
  array[index] = value;
  Expect.equals(value.x, array[index].x);
  Expect.equals(value.y, array[index].y);
}

void testLoadStoreDeoptDriver() {
  final list = Float64x2List(4);
  final value = Float64x2(1.0, 2.0);
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
    // non-Float64x2 value.
    testLoadStoreDeopt(list, 0, 4.toDouble());
  } catch (_) {}
  for (int i = 0; i < 20; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
  try {
    // non-Float64x2List list.
    testLoadStoreDeopt([Float64x2(2.0, 3.0)], 0, value);
  } catch (_) {}
  for (int i = 0; i < 20; i++) {
    testLoadStoreDeopt(list, 0, value);
  }
}

void testListZero() {
  final list = Float64x2List(1);
  Expect.equals(0.0, list[0].x);
  Expect.equals(0.0, list[0].y);
}

void testView(Float64x2List array) {
  Expect.equals(8, array.length);
  Expect.equals(0.0, array[0].x);
  Expect.equals(1.0, array[0].y);
  Expect.equals(2.0, array[1].x);
  Expect.equals(3.0, array[1].y);
}

void testSublist(Float64x2List array) {
  Expect.equals(8, array.length);
  var a = array.sublist(0, 1);
  Expect.equals(1, a.length);
  Expect.equals(0.0, a[0].x);
  Expect.equals(1.0, a[0].y);
  a = array.sublist(1, 2);
  Expect.equals(2.0, a[0].x);
  Expect.equals(3.0, a[0].y);
  a = array.sublist(0);
  Expect.equals(a.length, array.length);
  for (int i = 0; i < array.length; i++) {
    Expect.equals(array[i].x, a[i].x);
    Expect.equals(array[i].y, a[i].y);
  }
}

void testSpecialValues(Float64x2List array) {
  /// Same as Expect.identical, but also works with NaNs and -0.0.
  void checkEquals(double expected, double actual) {
    if (expected.isNaN) {
      Expect.isTrue(actual.isNaN);
    } else if (expected == 0.0 && expected.isNegative) {
      Expect.isTrue(actual == 0.0 && actual.isNegative);
    } else {
      Expect.equals(expected, actual);
    }
  }

  // Float64x2 lanes are IEEE doubles, so every value is stored exactly.
  final values = [
    0.0,
    -0.0,
    5e-324,
    2.2250738585072014e-308,
    1.0,
    4294967296.0,
    9007199254740992.0,
    1.7976931348623157e+308,
    double.infinity,
    -double.infinity,
    double.nan,
  ];

  for (final input in values) {
    var f = Float64x2(input, 2.0);
    array[0] = f;
    f = array[0];
    checkEquals(input, f.x);
    Expect.equals(2.0, f.y);

    f = Float64x2(1.0, input);
    array[1] = f;
    f = array[1];
    Expect.equals(1.0, f.x);
    checkEquals(input, f.y);
  }
}

void main() {
  final list = Float64x2List(8);
  for (int i = 0; i < 20; i++) {
    testLoadStore(list);
  }
  for (int i = 0; i < 20; i++) {
    testSwap(list);
  }

  final doubleList = Float64List(16);
  for (int i = 0; i < doubleList.length; i++) {
    doubleList[i] = i.toDouble();
  }
  final view = Float64x2List.view(doubleList.buffer);
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
