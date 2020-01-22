// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library int32x4_sign_mask;

import 'dart:typed_data';
import 'package:expect/expect.dart';

void testImmediates() {
  var f = new Int32x4(1, 2, 3, 4);
  var m = f.signMask;
  Expect.equals(0x0, m);
  f = new Int32x4(-1, -2, -3, -4);
  m = f.signMask;
  Expect.equals(0xf, m);
  f = new Int32x4.bool(true, false, false, false);
  m = f.signMask;
  Expect.equals(0x1, m);
  f = new Int32x4.bool(false, true, false, false);
  m = f.signMask;
  Expect.equals(0x2, m);
  f = new Int32x4.bool(false, false, true, false);
  m = f.signMask;
  Expect.equals(0x4, m);
  f = new Int32x4.bool(false, false, false, true);
  m = f.signMask;
  Expect.equals(0x8, m);
}

void testZero() {
  var f = new Int32x4(0, 0, 0, 0);
  var m = f.signMask;
  Expect.equals(0x0, m);
  f = new Int32x4(-0, -0, -0, -0);
  m = f.signMask;
  Expect.equals(0x0, m);
}

void testLogic() {
  var a = new Int32x4(0x80000000, 0x80000000, 0x80000000, 0x80000000);
  var b = new Int32x4(0x70000000, 0x70000000, 0x70000000, 0x70000000);
  var c = new Int32x4(0xf0000000, 0xf0000000, 0xf0000000, 0xf0000000);
  var m1 = (a & c).signMask;
  Expect.equals(0xf, m1);
  var m2 = (a & b).signMask;
  Expect.equals(0x0, m2);
  var m3 = (b ^ a).signMask;
  Expect.equals(0xf, m3);
  var m4 = (b | c).signMask;
  Expect.equals(0xf, m4);
}

main() {
  for (int i = 0; i < 2000; i++) {
    testImmediates();
    testZero();
    testLogic();
  }
}
