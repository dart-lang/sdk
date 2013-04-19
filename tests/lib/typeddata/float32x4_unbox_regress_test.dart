// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--deoptimization_counter_threshold=1000

// Library tag to be able to run in html test framework.
library float32x4_unbox_regress_test;

import 'package:expect/expect.dart';
import 'dart:typeddata';

testListStore(array, index, value) {
  array[index] = value;
}

void testListStoreDeopt() {
  var list;
  var value = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var smi = 12;
  list = new Float32x4List(8);
  for (int i = 0; i < 3000; i++) {
    testListStore(list, 0, value);
  }

  try {
    // Without a proper check for SMI in the Float32x4 unbox instruction
    // this might trigger a crash.
    testListStore(list, 0, smi);
  } catch (_) { }
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
  for (int i = 0; i < 3000; i++) {
    testAdd(a, b);
  }

  try {
    testAdd(a, smi);
  } catch (_) {}
}

main() {
  testListStoreDeopt();
  testAddDeopt();
}
