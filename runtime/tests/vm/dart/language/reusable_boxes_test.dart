// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correct handling reusable boxes.
// VMOptions=--optimization_counter_threshold=100 --no-background_compilation

library reusable_boxes_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

class D {
  var a = 0.0;
  var b = 1.0;
  dynamic c = 2.0;
  test() {
    a = 0.0;
    b = 1.0;
    c = a + b;
    return c;
  }

  testParam(x, y) {
    x = x * x;
    y = y * y;
    c = x + y;
  }
}

testD() {
  var f = new D();
  var r = 0.0;
  for (var i = 0; i < 20; i++) {
    r += f.test();
  }
  Expect.equals(20.0, r);
  // Trigger a deopt of test.
  f.testParam(new Float32x4(1.0, 2.0, 3.0, 4.0), new Float32x4.zero());
  r = 0.0;
  for (var i = 0; i < 20; i++) {
    r += f.test();
  }
  Expect.equals(20.0, r);
}

class F {
  var a = new Float32x4.zero();
  var b = new Float32x4(1.0, 2.0, 3.0, 4.0);
  dynamic c = new Float32x4.zero();
  test() {
    a = new Float32x4.zero();
    b = new Float32x4(1.0, 2.0, 3.0, 4.0);
    c = a + b;
    return c;
  }

  testParam(x, y) {
    x = x * x;
    y = y * y;
    c = x + y;
  }
}

testF() {
  var f = new F();
  var r = new Float32x4.zero();
  for (var i = 0; i < 20; i++) {
    r += f.test();
  }
  Expect.equals(20.0, r.x);
  Expect.equals(40.0, r.y);
  Expect.equals(60.0, r.z);
  Expect.equals(80.0, r.w);
  // Trigger a deopt of test.
  f.testParam(1.0, 2.0);
  r = new Float32x4.zero();
  for (var i = 0; i < 20; i++) {
    r += f.test();
  }
  Expect.equals(20.0, r.x);
  Expect.equals(40.0, r.y);
  Expect.equals(60.0, r.z);
  Expect.equals(80.0, r.w);
}

main() {
  testD();
  testF();
}
