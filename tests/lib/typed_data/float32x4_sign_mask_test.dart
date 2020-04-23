// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library float32x4_sign_mask;

import 'dart:typed_data';
import 'package:expect/expect.dart';

void testImmediates() {
  var f = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var m = f.signMask;
  Expect.equals(0x0, m);
  f = new Float32x4(-1.0, -2.0, -3.0, -0.0);
  m = f.signMask;
  Expect.equals(0xf, m);
  f = new Float32x4(-1.0, 2.0, 3.0, 4.0);
  m = f.signMask;
  Expect.equals(0x1, m);
  f = new Float32x4(1.0, -2.0, 3.0, 4.0);
  m = f.signMask;
  Expect.equals(0x2, m);
  f = new Float32x4(1.0, 2.0, -3.0, 4.0);
  m = f.signMask;
  Expect.equals(0x4, m);
  f = new Float32x4(1.0, 2.0, 3.0, -4.0);
  m = f.signMask;
  Expect.equals(0x8, m);
}

void testZero() {
  var f = new Float32x4(0.0, 0.0, 0.0, 0.0);
  var m = f.signMask;
  Expect.equals(0x0, m);
  f = new Float32x4(-0.0, -0.0, -0.0, -0.0);
  m = f.signMask;
  Expect.equals(0xf, m);
}

void testArithmetic() {
  var a = new Float32x4(1.0, 1.0, 1.0, 1.0);
  var b = new Float32x4(2.0, 2.0, 2.0, 2.0);
  var c = new Float32x4(-1.0, -1.0, -1.0, -1.0);
  var m1 = (a - b).signMask;
  Expect.equals(0xf, m1);
  var m2 = (b - a).signMask;
  Expect.equals(0x0, m2);
  var m3 = (c * c).signMask;
  Expect.equals(0x0, m3);
  var m4 = (a * c).signMask;
  Expect.equals(0xf, m4);
}

main() {
  for (int i = 0; i < 2000; i++) {
    testImmediates();
    testZero();
    testArithmetic();
  }
}
