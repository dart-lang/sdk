// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library uint32x4_arithmetic_test;

import 'dart:typed_data';
import "package:expect/expect.dart";

testAdd() {
  var m = new Int32x4(0, 0, 0, 0);
  var n = new Int32x4(-1, -1, -1, -1);
  var o = m + n;
  Expect.equals(-1, o.x);
  Expect.equals(-1, o.y);
  Expect.equals(-1, o.z);
  Expect.equals(-1, o.w);

  m = new Int32x4(0, 0, 0, 0);
  n = new Int32x4(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
  o = m + n;
  Expect.equals(-1, o.x);
  Expect.equals(-1, o.y);
  Expect.equals(-1, o.z);
  Expect.equals(-1, o.w);

  n = new Int32x4(1, 1, 1, 1);
  m = new Int32x4(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
  o = m + n;
  Expect.equals(0, o.x);
  Expect.equals(0, o.y);
  Expect.equals(0, o.z);
  Expect.equals(0, o.w);

  n = new Int32x4(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
  m = new Int32x4(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
  o = m + n;
  Expect.equals(-2, o.x);
  Expect.equals(-2, o.y);
  Expect.equals(-2, o.z);
  Expect.equals(-2, o.w);

  n = new Int32x4(1, 0, 0, 0);
  m = new Int32x4(2, 0, 0, 0);
  o = n + m;
  Expect.equals(3, o.x);
  Expect.equals(0, o.y);
  Expect.equals(0, o.z);
  Expect.equals(0, o.w);

  n = new Int32x4(1, 3, 0, 0);
  m = new Int32x4(2, 4, 0, 0);
  o = n + m;
  Expect.equals(3, o.x);
  Expect.equals(7, o.y);
  Expect.equals(0, o.z);
  Expect.equals(0, o.w);

  n = new Int32x4(1, 3, 5, 0);
  m = new Int32x4(2, 4, 6, 0);
  o = n + m;
  Expect.equals(3, o.x);
  Expect.equals(7, o.y);
  Expect.equals(11, o.z);
  Expect.equals(0, o.w);

  n = new Int32x4(1, 3, 5, 7);
  m = new Int32x4(-2, -4, -6, -8);
  o = n + m;
  Expect.equals(-1, o.x);
  Expect.equals(-1, o.y);
  Expect.equals(-1, o.z);
  Expect.equals(-1, o.w);
}

testSub() {
  var m = new Int32x4(0, 0, 0, 0);
  var n = new Int32x4(1, 1, 1, 1);
  var o = m - n;
  Expect.equals(-1, o.x);
  Expect.equals(-1, o.y);
  Expect.equals(-1, o.z);
  Expect.equals(-1, o.w);

  o = n - m;
  Expect.equals(1, o.x);
  Expect.equals(1, o.y);
  Expect.equals(1, o.z);
  Expect.equals(1, o.w);
}

const int53 = 0x20000000000000; // 2^53.
final usingJavaScriptNumbers = (int53 + 1) == int53;

testTruncation() {
  // Check that various bits from bit 32 and up are masked away.
  var base = usingJavaScriptNumbers ? 0x1BCCDD00000000 : 0xAABBCCDD00000000;
  var x1 = new Int32x4(base + 1, 0, 0, 0);
  Expect.equals(1, x1.x);

  // Check that all even bits up to bit 30 are preserved.
  var x2 = new Int32x4(base + 0x55555555, 0, 0, 0);
  Expect.equals(0x55555555, x2.x);

  // Check that the odd bits up to bit 31 are preserved, and that
  // bit 31 is treated as a sign bit.
  var x3 = new Int32x4(base + 0xAAAAAAAA, 0, 0, 0);
  const signExtended = -1431655766; // 0xFFFFFFFFAAAAAAAA or 0x3FFFFFAAAAAAAA.
  Expect.equals(signExtended, x3.x);

  // Check that all bits from bit 32 and up are masked away.
  var highBase = 0xFFFFFFFF10000000;
  var x4 = new Int32x4(highBase, 0, 0, 0);
  Expect.equals(0x10000000, x4.x);
}

main() {
  for (int i = 0; i < 20; i++) {
    testAdd();
    testSub();
    testTruncation();
  }
}
