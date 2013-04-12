// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library tag to be able to run in html test framework.
library float32x4_test;

import "package:expect/expect.dart";
import 'dart:typeddata';

testAdd() {
  var m = new Float32x4(-1.0, -2.0, -3.0, -4.0);
  var n = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var o = m + n;
  Expect.equals(0.0, o.x);
  Expect.equals(0.0, o.y);
  Expect.equals(0.0, o.z);
  Expect.equals(0.0, o.w);
}

testNegate() {
  var m = new Float32x4(1.0, 2.0, -3.0, -4.0);
  m = -m;
  Expect.equals(-1.0, m.x);
  Expect.equals(-2.0, m.y);
  Expect.equals(3.0, m.z);
  Expect.equals(4.0, m.w);
}

testSub() {
  var m = new Float32x4(-1.0, -2.0, -3.0, -4.0);
  var n = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var o = m - n;
  Expect.equals(-2.0, o.x);
  Expect.equals(-4.0, o.y);
  Expect.equals(-6.0, o.z);
  Expect.equals(-8.0, o.w);
}

testMul() {
  var m = new Float32x4(-1.0, -2.0, -3.0, -4.0);
  var n = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var o = m * n;
  Expect.equals(-1.0, o.x);
  Expect.equals(-4.0, o.y);
  Expect.equals(-9.0, o.z);
  Expect.equals(-16.0, o.w);
}

testDiv() {
  var m = new Float32x4(-1.0, -2.0, -3.0, -4.0);
  var n = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var o = m / n;
  Expect.equals(-1.0, o.x);
  Expect.equals(-1.0, o.y);
  Expect.equals(-1.0, o.z);
  Expect.equals(-1.0, o.w);
}

testComparison() {
  var m = new Float32x4(1.0, 2.0, 0.1, 0.001);
  var n = new Float32x4(2.0, 2.0, 0.001, 0.1);
  var cmp;
  cmp = m.lessThan(n);
  Expect.equals(0xFFFFFFFF, cmp.x);
  Expect.equals(0x0, cmp.y);
  Expect.equals(0x0, cmp.z);
  Expect.equals(0xFFFFFFFF, cmp.w);

  cmp = m.lessThanOrEqual(n);
  Expect.equals(0xFFFFFFFF, cmp.x);
  Expect.equals(0xFFFFFFFF, cmp.y);
  Expect.equals(0x0, cmp.z);
  Expect.equals(0xFFFFFFFF, cmp.w);

  cmp = m.equal(n);
  Expect.equals(0x0, cmp.x);
  Expect.equals(0xFFFFFFFF, cmp.y);
  Expect.equals(0x0, cmp.z);
  Expect.equals(0x0, cmp.w);

  cmp = m.notEqual(n);
  Expect.equals(0xFFFFFFFF, cmp.x);
  Expect.equals(0x0, cmp.y);
  Expect.equals(0xFFFFFFFF, cmp.z);
  Expect.equals(0xFFFFFFFF, cmp.w);

  cmp = m.greaterThanOrEqual(n);
  Expect.equals(0x0, cmp.x);
  Expect.equals(0xFFFFFFFF, cmp.y);
  Expect.equals(0xFFFFFFFF, cmp.z);
  Expect.equals(0x0, cmp.w);

  cmp = m.greaterThan(n);
  Expect.equals(0x0, cmp.x);
  Expect.equals(0x0, cmp.y);
  Expect.equals(0xFFFFFFFF, cmp.z);
  Expect.equals(0x0, cmp.w);
}

testAbs() {
  var m = new Float32x4(1.0, -2.0, 3.0, -4.0);
  m = m.abs();
  Expect.equals(1.0, m.x);
  Expect.equals(2.0, m.y);
  Expect.equals(3.0, m.z);
  Expect.equals(4.0, m.w);
}

testScale() {
  var m = new Float32x4(1.0, -2.0, 3.0, -4.0);
  m = m.scale(20.0);
  Expect.equals(20.0, m.x);
  Expect.equals(-40.0, m.y);
  Expect.equals(60.0, m.z);
  Expect.equals(-80.0, m.w);
}

testClamp() {
  var m = new Float32x4(1.0, -2.0, 3.0, -4.0);
  var lo = new Float32x4(0.0, 0.0, 0.0, 0.0);
  var hi = new Float32x4(2.0, 2.0, 2.0, 2.0);
  m = m.clamp(lo, hi);
  Expect.equals(1.0, m.x);
  Expect.equals(0.0, m.y);
  Expect.equals(2.0, m.z);
  Expect.equals(0.0, m.w);
}

testShuffle() {
  var m = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var xxxx = m.xxxx;
  Expect.equals(1.0, xxxx.x);
  Expect.equals(1.0, xxxx.y);
  Expect.equals(1.0, xxxx.z);
  Expect.equals(1.0, xxxx.w);
  var yyyy = m.yyyy;
  Expect.equals(2.0, yyyy.x);
  Expect.equals(2.0, yyyy.y);
  Expect.equals(2.0, yyyy.z);
  Expect.equals(2.0, yyyy.w);
  var zzzz = m.zzzz;
  Expect.equals(3.0, zzzz.x);
  Expect.equals(3.0, zzzz.y);
  Expect.equals(3.0, zzzz.z);
  Expect.equals(3.0, zzzz.w);
  var wwww = m.wwww;
  Expect.equals(4.0, wwww.x);
  Expect.equals(4.0, wwww.y);
  Expect.equals(4.0, wwww.z);
  Expect.equals(4.0, wwww.w);
}

testMin() {
  var m = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var n = new Float32x4(1.0, 0.0, 2.5, 5.0);
  m = m.min(n);
  Expect.equals(1.0, m.x);
  Expect.equals(0.0, m.y);
  Expect.equals(2.5, m.z);
  Expect.equals(4.0, m.w);
}

testMax() {
  var m = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var n = new Float32x4(1.0, 0.0, 2.5, 5.0);
  m = m.max(n);
  Expect.equals(1.0, m.x);
  Expect.equals(2.0, m.y);
  Expect.equals(3.0, m.z);
  Expect.equals(5.0, m.w);
}

testSqrt() {
  var m = new Float32x4(1.0, 4.0, 9.0, 16.0);
  m = m.sqrt();
  Expect.equals(1.0, m.x);
  Expect.equals(2.0, m.y);
  Expect.equals(3.0, m.z);
  Expect.equals(4.0, m.w);
}

testReciprocal() {
  var m = new Float32x4(1.0, 4.0, 9.0, 16.0);
  m = m.reciprocal();
  Expect.approxEquals(1.0, m.x);
  Expect.approxEquals(0.25, m.y);
  Expect.approxEquals(0.1111111, m.z);
  Expect.approxEquals(0.0625, m.w);
}

testReciprocalSqrt() {
  var m = new Float32x4(1.0, 0.25, 0.111111, 0.0625);
  m = m.reciprocalSqrt();
  Expect.approxEquals(1.0, m.x);
  Expect.approxEquals(2.0, m.y);
  Expect.approxEquals(3.0, m.z);
  Expect.approxEquals(4.0, m.w);
}

testSelect() {
  var m = new Uint32x4.bool(true, true, false, false);
  var t = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var f = new Float32x4(5.0, 6.0, 7.0, 8.0);
  var s = m.select(t, f);
  Expect.equals(1.0, s.x);
  Expect.equals(2.0, s.y);
  Expect.equals(7.0, s.z);
  Expect.equals(8.0, s.w);
}

testConversions() {
  var m = new Uint32x4(0x3F800000, 0x40000000, 0x40400000, 0x40800000);
  var n = m.toFloat32x4();
  Expect.equals(1.0, n.x);
  Expect.equals(2.0, n.y);
  Expect.equals(3.0, n.z);
  Expect.equals(4.0, n.w);
  n = new Float32x4(5.0, 6.0, 7.0, 8.0);
  m = n.toUint32x4();
  Expect.equals(0x40A00000, m.x);
  Expect.equals(0x40C00000, m.y);
  Expect.equals(0x40E00000, m.z);
  Expect.equals(0x41000000, m.w);
  // Flip sign using bit-wise operators.
  n = new Float32x4(9.0, 10.0, 11.0, 12.0);
  m = new Uint32x4(0x80000000, 0x80000000, 0x80000000, 0x80000000);
  var nMask = n.toUint32x4();
  nMask = nMask ^ m; // flip sign.
  n = nMask.toFloat32x4();
  Expect.equals(-9.0, n.x);
  Expect.equals(-10.0, n.y);
  Expect.equals(-11.0, n.z);
  Expect.equals(-12.0, n.w);
  nMask = n.toUint32x4();
  nMask = nMask ^ m; // flip sign.
  n = nMask.toFloat32x4();
  Expect.equals(9.0, n.x);
  Expect.equals(10.0, n.y);
  Expect.equals(11.0, n.z);
  Expect.equals(12.0, n.w);
}


testBitOperators() {
  var m = new Uint32x4(0xAAAAAAAA, 0xAAAAAAAA, 0xAAAAAAAA, 0xAAAAAAAA);
  var n = new Uint32x4(0x55555555, 0x55555555, 0x55555555, 0x55555555);
  Expect.equals(0xAAAAAAAA, m.x);
  Expect.equals(0xAAAAAAAA, m.y);
  Expect.equals(0xAAAAAAAA, m.z);
  Expect.equals(0xAAAAAAAA, m.w);
  Expect.equals(0x55555555, n.x);
  Expect.equals(0x55555555, n.y);
  Expect.equals(0x55555555, n.z);
  Expect.equals(0x55555555, n.w);
  Expect.equals(true, n.flagX);
  Expect.equals(true, n.flagY);
  Expect.equals(true, n.flagZ);
  Expect.equals(true, n.flagW);
  var o = m|n;  // or
  Expect.equals(0xFFFFFFFF, o.x);
  Expect.equals(0xFFFFFFFF, o.y);
  Expect.equals(0xFFFFFFFF, o.z);
  Expect.equals(0xFFFFFFFF, o.w);
  Expect.equals(true, o.flagX);
  Expect.equals(true, o.flagY);
  Expect.equals(true, o.flagZ);
  Expect.equals(true, o.flagW);
  o = m&n;  // and
  Expect.equals(0x0, o.x);
  Expect.equals(0x0, o.y);
  Expect.equals(0x0, o.z);
  Expect.equals(0x0, o.w);
  n = n.withX(0xAAAAAAAA);
  n = n.withY(0xAAAAAAAA);
  n = n.withZ(0xAAAAAAAA);
  n = n.withW(0xAAAAAAAA);
  Expect.equals(0xAAAAAAAA, n.x);
  Expect.equals(0xAAAAAAAA, n.y);
  Expect.equals(0xAAAAAAAA, n.z);
  Expect.equals(0xAAAAAAAA, n.w);
  o = m^n;  // xor
  Expect.equals(0x0, o.x);
  Expect.equals(0x0, o.y);
  Expect.equals(0x0, o.z);
  Expect.equals(0x0, o.w);
  Expect.equals(false, o.flagX);
  Expect.equals(false, o.flagY);
  Expect.equals(false, o.flagZ);
  Expect.equals(false, o.flagW);
}

testSetters() {
  var f = new Float32x4.zero();
  Expect.equals(0.0, f.x);
  Expect.equals(0.0, f.y);
  Expect.equals(0.0, f.z);
  Expect.equals(0.0, f.w);
  f = f.withX(4.0);
  Expect.equals(4.0, f.x);
  f = f.withY(3.0);
  Expect.equals(3.0, f.y);
  f = f.withZ(2.0);
  Expect.equals(2.0, f.z);
  f = f.withW(1.0);
  Expect.equals(1.0, f.w);
  f = new Float32x4.zero();
  f = f.withX(4.0).withZ(2.0).withW(1.0).withY(3.0);
  Expect.equals(4.0, f.x);
  Expect.equals(3.0, f.y);
  Expect.equals(2.0, f.z);
  Expect.equals(1.0, f.w);
  var m = new Uint32x4.bool(false, false, false, false);
  Expect.equals(false, m.flagX);
  Expect.equals(false, m.flagY);
  Expect.equals(false, m.flagZ);
  Expect.equals(false, m.flagW);
  m = m.withFlagX(true);
  Expect.equals(true, m.flagX);
  Expect.equals(false, m.flagY);
  Expect.equals(false, m.flagZ);
  Expect.equals(false, m.flagW);
  m = m.withFlagY(true);
  Expect.equals(true, m.flagX);
  Expect.equals(true, m.flagY);
  Expect.equals(false, m.flagZ);
  Expect.equals(false, m.flagW);
  m = m.withFlagZ(true);
  Expect.equals(true, m.flagX);
  Expect.equals(true, m.flagY);
  Expect.equals(true, m.flagZ);
  Expect.equals(false, m.flagW);
  m = m.withFlagW(true);
  Expect.equals(true, m.flagX);
  Expect.equals(true, m.flagY);
  Expect.equals(true, m.flagZ);
  Expect.equals(true, m.flagW);
}

testGetters() {
  var f = new Float32x4(1.0, 2.0, 3.0, 4.0);
  Expect.equals(1.0, f.x);
  Expect.equals(2.0, f.y);
  Expect.equals(3.0, f.z);
  Expect.equals(4.0, f.w);
  var m = new Uint32x4.bool(false, true, true, false);
  Expect.equals(false, m.flagX);
  Expect.equals(true, m.flagY);
  Expect.equals(true, m.flagZ);
  Expect.equals(false, m.flagW);
}

main() {
  for (int i = 0; i < 3000; i++) {
    testAdd();
    testGetters();
    testSetters();
    testBitOperators();
    testConversions();
    testSelect();
    testShuffle();
    testSub();
    testNegate();
    testMul();
    testDiv();
    testComparison();
    testScale();
    testClamp();
    testAbs();
    testMin();
    testMax();
    testSqrt();
    testReciprocal();
    testReciprocalSqrt();
  }
}
