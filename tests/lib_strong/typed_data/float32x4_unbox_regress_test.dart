// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--deoptimization_counter_threshold=1000 --optimization-counter-threshold=10

// Library tag to be able to run in html test framework.
library float32x4_unbox_regress_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

testListStore(array, index, value) {
  array[index] = value;
}

void testListStoreDeopt() {
  var list;
  var value = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var smi = 12;
  list = new Float32x4List(8);
  for (int i = 0; i < 20; i++) {
    testListStore(list, 0, value);
  }

  try {
    // Without a proper check for SMI in the Float32x4 unbox instruction
    // this might trigger a crash.
    testListStore(list, 0, smi);
  } catch (_) {}
}

testAdd(a, b) {
  var c = a + b;
  Expect.equals(3.0, c.x);
  Expect.equals(5.0, c.y);
  Expect.equals(7.0, c.z);
  Expect.equals(9.0, c.w);
}

void testAddDeopt() {
  var a = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var b = new Float32x4(2.0, 3.0, 4.0, 5.0);
  var smi = 12;
  for (int i = 0; i < 20; i++) {
    testAdd(a, b);
  }

  try {
    testAdd(a, smi);
  } catch (_) {}
}

testGet(a) {
  var c = a.x + a.y + a.z + a.w;
  Expect.equals(10.0, c);
}

void testGetDeopt() {
  var a = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var smi = 12;
  for (int i = 0; i < 20; i++) {
    testGet(a);
  }

  try {
    testGet(12);
  } catch (_) {}

  for (int i = 0; i < 20; i++) {
    testGet(a);
  }
}

void testComparison(a, b) {
  Int32x4 r = a.equal(b);
  Expect.equals(true, r.flagX);
  Expect.equals(false, r.flagY);
  Expect.equals(false, r.flagZ);
  Expect.equals(true, r.flagW);
}

void testComparisonDeopt() {
  var a = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var b = new Float32x4(1.0, 2.1, 3.1, 4.0);
  var smi = 12;

  for (int i = 0; i < 20; i++) {
    testComparison(a, b);
  }

  try {
    testComparison(a, smi);
  } catch (_) {}

  for (int i = 0; i < 20; i++) {
    testComparison(a, b);
  }

  try {
    testComparison(smi, a);
  } catch (_) {}

  for (int i = 0; i < 20; i++) {
    testComparison(a, b);
  }
}

main() {
  testListStoreDeopt();
  testAddDeopt();
  testGetDeopt();
  testComparisonDeopt();
}
