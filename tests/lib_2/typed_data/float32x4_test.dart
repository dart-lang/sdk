// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation
// VMOptions=--no-intrinsify

// Library tag to be able to run in html test framework.
library float32x4_test;

import 'dart:typed_data';
import "package:expect/expect.dart";

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
  Expect.equals(-1, cmp.x);
  Expect.equals(0x0, cmp.y);
  Expect.equals(0x0, cmp.z);
  Expect.equals(-1, cmp.w);

  cmp = m.lessThanOrEqual(n);
  Expect.equals(-1, cmp.x);
  Expect.equals(-1, cmp.y);
  Expect.equals(0x0, cmp.z);
  Expect.equals(-1, cmp.w);

  cmp = m.equal(n);
  Expect.equals(0x0, cmp.x);
  Expect.equals(-1, cmp.y);
  Expect.equals(0x0, cmp.z);
  Expect.equals(0x0, cmp.w);

  cmp = m.notEqual(n);
  Expect.equals(-1, cmp.x);
  Expect.equals(0x0, cmp.y);
  Expect.equals(-1, cmp.z);
  Expect.equals(-1, cmp.w);

  cmp = m.greaterThanOrEqual(n);
  Expect.equals(0x0, cmp.x);
  Expect.equals(-1, cmp.y);
  Expect.equals(-1, cmp.z);
  Expect.equals(0x0, cmp.w);

  cmp = m.greaterThan(n);
  Expect.equals(0x0, cmp.x);
  Expect.equals(0x0, cmp.y);
  Expect.equals(-1, cmp.z);
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
  var xxxx = m.shuffle(Float32x4.XXXX);
  Expect.equals(1.0, xxxx.x);
  Expect.equals(1.0, xxxx.y);
  Expect.equals(1.0, xxxx.z);
  Expect.equals(1.0, xxxx.w);
  var yyyy = m.shuffle(Float32x4.YYYY);
  Expect.equals(2.0, yyyy.x);
  Expect.equals(2.0, yyyy.y);
  Expect.equals(2.0, yyyy.z);
  Expect.equals(2.0, yyyy.w);
  var zzzz = m.shuffle(Float32x4.ZZZZ);
  Expect.equals(3.0, zzzz.x);
  Expect.equals(3.0, zzzz.y);
  Expect.equals(3.0, zzzz.z);
  Expect.equals(3.0, zzzz.w);
  var wwww = m.shuffle(Float32x4.WWWW);
  Expect.equals(4.0, wwww.x);
  Expect.equals(4.0, wwww.y);
  Expect.equals(4.0, wwww.z);
  Expect.equals(4.0, wwww.w);
  var wzyx = m.shuffle(Float32x4.WZYX);
  Expect.equals(4.0, wzyx.x);
  Expect.equals(3.0, wzyx.y);
  Expect.equals(2.0, wzyx.z);
  Expect.equals(1.0, wzyx.w);
  var wwzz = m.shuffle(Float32x4.WWZZ);
  Expect.equals(4.0, wwzz.x);
  Expect.equals(4.0, wwzz.y);
  Expect.equals(3.0, wwzz.z);
  Expect.equals(3.0, wwzz.w);
  var xxyy = m.shuffle(Float32x4.XXYY);
  Expect.equals(1.0, xxyy.x);
  Expect.equals(1.0, xxyy.y);
  Expect.equals(2.0, xxyy.z);
  Expect.equals(2.0, xxyy.w);
  var yyww = m.shuffle(Float32x4.YYWW);
  Expect.equals(2.0, yyww.x);
  Expect.equals(2.0, yyww.y);
  Expect.equals(4.0, yyww.z);
  Expect.equals(4.0, yyww.w);
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
  Expect.approxEquals(1.0, m.x, 0.001);
  Expect.approxEquals(0.25, m.y, 0.001);
  Expect.approxEquals(0.1111111, m.z, 0.001);
  Expect.approxEquals(0.0625, m.w, 0.001);
}

testReciprocalSqrt() {
  var m = new Float32x4(1.0, 0.25, 0.111111, 0.0625);
  m = m.reciprocalSqrt();
  Expect.approxEquals(1.0, m.x, 0.001);
  Expect.approxEquals(2.0, m.y, 0.001);
  Expect.approxEquals(3.0, m.z, 0.001);
  Expect.approxEquals(4.0, m.w, 0.001);
}

testSelect() {
  var m = new Int32x4.bool(true, true, false, false);
  var t = new Float32x4(1.0, 2.0, 3.0, 4.0);
  var f = new Float32x4(5.0, 6.0, 7.0, 8.0);
  var s = m.select(t, f);
  Expect.equals(1.0, s.x);
  Expect.equals(2.0, s.y);
  Expect.equals(7.0, s.z);
  Expect.equals(8.0, s.w);
}

testConversions() {
  var m = new Int32x4(0x3F800000, 0x40000000, 0x40400000, 0x40800000);
  var n = new Float32x4.fromInt32x4Bits(m);
  Expect.equals(1.0, n.x);
  Expect.equals(2.0, n.y);
  Expect.equals(3.0, n.z);
  Expect.equals(4.0, n.w);
  n = new Float32x4(5.0, 6.0, 7.0, 8.0);
  m = new Int32x4.fromFloat32x4Bits(n);
  Expect.equals(0x40A00000, m.x);
  Expect.equals(0x40C00000, m.y);
  Expect.equals(0x40E00000, m.z);
  Expect.equals(0x41000000, m.w);
  // Flip sign using bit-wise operators.
  n = new Float32x4(9.0, 10.0, 11.0, 12.0);
  m = new Int32x4(0x80000000, 0x80000000, 0x80000000, 0x80000000);
  var nMask = new Int32x4.fromFloat32x4Bits(n);
  nMask = nMask ^ m; // flip sign.
  n = new Float32x4.fromInt32x4Bits(nMask);
  Expect.equals(-9.0, n.x);
  Expect.equals(-10.0, n.y);
  Expect.equals(-11.0, n.z);
  Expect.equals(-12.0, n.w);
  nMask = new Int32x4.fromFloat32x4Bits(n);
  nMask = nMask ^ m; // flip sign.
  n = new Float32x4.fromInt32x4Bits(nMask);
  Expect.equals(9.0, n.x);
  Expect.equals(10.0, n.y);
  Expect.equals(11.0, n.z);
  Expect.equals(12.0, n.w);
}

testBitOperators() {
  var m = new Int32x4(0xAAAAAAA, 0xAAAAAAA, 0xAAAAAAA, 0xAAAAAAA);
  var n = new Int32x4(0x5555555, 0x5555555, 0x5555555, 0x5555555);
  Expect.equals(0xAAAAAAA, m.x);
  Expect.equals(0xAAAAAAA, m.y);
  Expect.equals(0xAAAAAAA, m.z);
  Expect.equals(0xAAAAAAA, m.w);
  Expect.equals(0x5555555, n.x);
  Expect.equals(0x5555555, n.y);
  Expect.equals(0x5555555, n.z);
  Expect.equals(0x5555555, n.w);
  Expect.equals(true, n.flagX);
  Expect.equals(true, n.flagY);
  Expect.equals(true, n.flagZ);
  Expect.equals(true, n.flagW);
  var o = m | n; // or
  Expect.equals(0xFFFFFFF, o.x);
  Expect.equals(0xFFFFFFF, o.y);
  Expect.equals(0xFFFFFFF, o.z);
  Expect.equals(0xFFFFFFF, o.w);
  Expect.equals(true, o.flagX);
  Expect.equals(true, o.flagY);
  Expect.equals(true, o.flagZ);
  Expect.equals(true, o.flagW);
  o = m & n; // and
  Expect.equals(0x0, o.x);
  Expect.equals(0x0, o.y);
  Expect.equals(0x0, o.z);
  Expect.equals(0x0, o.w);
  n = n.withX(0xAAAAAAA);
  n = n.withY(0xAAAAAAA);
  n = n.withZ(0xAAAAAAA);
  n = n.withW(0xAAAAAAA);
  Expect.equals(0xAAAAAAA, n.x);
  Expect.equals(0xAAAAAAA, n.y);
  Expect.equals(0xAAAAAAA, n.z);
  Expect.equals(0xAAAAAAA, n.w);
  o = m ^ n; // xor
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
  var m = new Int32x4.bool(false, false, false, false);
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
  var m = new Int32x4.bool(false, true, true, false);
  Expect.equals(false, m.flagX);
  Expect.equals(true, m.flagY);
  Expect.equals(true, m.flagZ);
  Expect.equals(false, m.flagW);
}

void testSplat() {
  var f = new Float32x4.splat(2.0);
  Expect.equals(2.0, f.x);
  Expect.equals(2.0, f.y);
  Expect.equals(2.0, f.z);
  Expect.equals(2.0, f.w);
}

void testZero() {
  var f = new Float32x4.zero();
  Expect.equals(0.0, f.x);
  Expect.equals(0.0, f.y);
  Expect.equals(0.0, f.z);
  Expect.equals(0.0, f.w);
}

void testConstructor() {
  var f = new Float32x4(1.0, 2.0, 3.0, 4.0);
  Expect.equals(1.0, f.x);
  Expect.equals(2.0, f.y);
  Expect.equals(3.0, f.z);
  Expect.equals(4.0, f.w);
}

void testBadArguments() {
  Expect.throws(
      () => new Float32x4(null, 2.0, 3.0, 4.0), (e) => e is ArgumentError);
  Expect.throws(
      () => new Float32x4(1.0, null, 3.0, 4.0), (e) => e is ArgumentError);
  Expect.throws(
      () => new Float32x4(1.0, 2.0, null, 4.0), (e) => e is ArgumentError);
  Expect.throws(
      () => new Float32x4(1.0, 2.0, 3.0, null), (e) => e is ArgumentError);
  // Use local variable typed as "dynamic" to avoid static warnings.
  dynamic str = "foo";
  Expect.throws(() => new Float32x4(str, 2.0, 3.0, 4.0),
      (e) => e is ArgumentError || e is TypeError);
  Expect.throws(() => new Float32x4(1.0, str, 3.0, 4.0),
      (e) => e is ArgumentError || e is TypeError);
  Expect.throws(() => new Float32x4(1.0, 2.0, str, 4.0),
      (e) => e is ArgumentError || e is TypeError);
  Expect.throws(() => new Float32x4(1.0, 2.0, 3.0, str),
      (e) => e is ArgumentError || e is TypeError);
}

void testSpecialValues() {
  /// Same as Expect.identical, but also works with NaNs and -0.0 for dart2js.
  void checkEquals(expected, actual) {
    if (expected.isNaN) {
      Expect.isTrue(actual.isNaN);
    } else if (expected == 0.0 && expected.isNegative) {
      Expect.isTrue(actual == 0.0 && actual.isNegative);
    } else {
      Expect.equals(expected, actual);
    }
  }

  var pairs = [
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
    [1.7976931348623157e+308, double.INFINITY],
    [0.49999999999999994, 0.5],
    [4503599627370497.0, 4503599627370496.0],
    [9007199254740991.0, 9007199254740992.0],
    [double.INFINITY, double.INFINITY],
    [double.NAN, double.NAN],
  ];

  var conserved = [
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

  var minusPairs = pairs.map((pair) {
    return [-pair[0], -pair[1]];
  });
  var conservedPairs = conserved.map((value) => [value, value]);

  var allTests = [pairs, minusPairs, conservedPairs].expand((x) => x);

  for (var pair in allTests) {
    var input = pair[0];
    var expected = pair[1];
    var f;
    f = new Float32x4(input, 2.0, 3.0, 4.0);
    checkEquals(expected, f.x);
    Expect.equals(2.0, f.y);
    Expect.equals(3.0, f.z);
    Expect.equals(4.0, f.w);

    f = new Float32x4(1.0, input, 3.0, 4.0);
    Expect.equals(1.0, f.x);
    checkEquals(expected, f.y);
    Expect.equals(3.0, f.z);
    Expect.equals(4.0, f.w);

    f = new Float32x4(1.0, 2.0, input, 4.0);
    Expect.equals(1.0, f.x);
    Expect.equals(2.0, f.y);
    checkEquals(expected, f.z);
    Expect.equals(4.0, f.w);

    f = new Float32x4(1.0, 2.0, 3.0, input);
    Expect.equals(1.0, f.x);
    Expect.equals(2.0, f.y);
    Expect.equals(3.0, f.z);
    checkEquals(expected, f.w);
  }
}

main() {
  for (int i = 0; i < 20; i++) {
    testConstructor();
    testSplat();
    testZero();
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
    testBadArguments();
    testSpecialValues();
  }
}
