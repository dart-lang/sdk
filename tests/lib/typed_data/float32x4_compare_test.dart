// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation
// VMOptions=--no-intrinsify

import "dart:typed_data";
import "package:expect/expect.dart";

testEqual() {
  var a = new Float32x4(
      double.nan, double.infinity, double.negativeInfinity, double.nan);
  var b = new Float32x4(0.0, 0.0, 0.0, double.nan);
  var c = a.equal(b);
  var d = b.equal(a);
  Expect.equals(0, c.x);
  Expect.equals(0, c.y);
  Expect.equals(0, c.z);
  Expect.equals(0, c.w);
  Expect.equals(0, d.x);
  Expect.equals(0, d.y);
  Expect.equals(0, d.z);
  Expect.equals(0, d.w);
}

testNotEqual() {
  var a = new Float32x4(
      double.nan, double.infinity, double.negativeInfinity, double.nan);
  var b = new Float32x4(0.0, 0.0, 0.0, double.nan);
  var c = a.notEqual(b);
  var d = b.notEqual(a);
  Expect.equals(-1, c.x);
  Expect.equals(-1, c.y);
  Expect.equals(-1, c.z);
  Expect.equals(-1, c.w);
  Expect.equals(-1, d.x);
  Expect.equals(-1, d.y);
  Expect.equals(-1, d.z);
  Expect.equals(-1, d.w);
}

testLessThan() {
  var a = new Float32x4(
      double.nan, double.infinity, double.negativeInfinity, double.nan);
  var b = new Float32x4(0.0, 0.0, 0.0, double.nan);
  var c = a.lessThan(b);
  var d = b.lessThan(a);
  Expect.equals(0, c.x);
  Expect.equals(0, c.y);
  Expect.equals(-1, c.z);
  Expect.equals(0, c.w);
  Expect.equals(0, d.x);
  Expect.equals(-1, d.y);
  Expect.equals(0, d.z);
  Expect.equals(0, d.w);
}

testLessThanOrEqual() {
  var a = new Float32x4(
      double.nan, double.infinity, double.negativeInfinity, double.nan);
  var b = new Float32x4(0.0, 0.0, 0.0, double.nan);
  var c = a.lessThanOrEqual(b);
  var d = b.lessThanOrEqual(a);
  Expect.equals(0, c.x);
  Expect.equals(0, c.y);
  Expect.equals(-1, c.z);
  Expect.equals(0, c.w);
  Expect.equals(0, d.x);
  Expect.equals(-1, d.y);
  Expect.equals(0, d.z);
  Expect.equals(0, d.w);
}

testGreaterThan() {
  var a = new Float32x4(
      double.nan, double.infinity, double.negativeInfinity, double.nan);
  var b = new Float32x4(0.0, 0.0, 0.0, double.nan);
  var c = a.greaterThan(b);
  var d = b.greaterThan(a);
  Expect.equals(0, c.x);
  Expect.equals(-1, c.y);
  Expect.equals(0, c.z);
  Expect.equals(0, c.w);
  Expect.equals(0, d.x);
  Expect.equals(0, d.y);
  Expect.equals(-1, d.z);
  Expect.equals(0, d.w);
}

testGreaterThanOrEqual() {
  var a = new Float32x4(
      double.nan, double.infinity, double.negativeInfinity, double.nan);
  var b = new Float32x4(0.0, 0.0, 0.0, double.nan);
  var c = a.greaterThanOrEqual(b);
  var d = b.greaterThan(a);
  Expect.equals(0, c.x);
  Expect.equals(-1, c.y);
  Expect.equals(0, c.z);
  Expect.equals(0, c.w);
  Expect.equals(0, d.x);
  Expect.equals(0, d.y);
  Expect.equals(-1, d.z);
  Expect.equals(0, d.w);
}

main() {
  for (int i = 0; i < 20; i++) {
    testEqual();
    testNotEqual();
    testLessThan();
    testLessThanOrEqual();
    testGreaterThan();
    testGreaterThanOrEqual();
  }
}
