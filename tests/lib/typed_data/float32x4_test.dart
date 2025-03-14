// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation
// VMOptions=--no-intrinsify

import 'dart:typed_data';
import "package:expect/expect.dart";

const nan = double.nan;
const inf = double.infinity;

/// Minimal positive 32-bit float value.
const min = 1.401298464324817e-45;

/// Maximal finite 32-bit float value.
const max = 3.4028234663852886e+38;

void testAdd() {
  var m = Float32x4(-1.0, -2.0, -3.0, -4.0);
  var n = Float32x4(1.0, 2.0, 3.0, 4.0);
  var o = m + n;
  checkEquals(0.0, o.x);
  checkEquals(0.0, o.y);
  checkEquals(0.0, o.z);
  checkEquals(0.0, o.w);

  var p = Float32x4(-0.0, inf, max, nan);
  var q = Float32x4(-0.0, -inf, max, 3.14);
  var r = p + q;
  checkEquals(-0.0, r.x);
  checkEquals(nan, r.y);
  checkEquals(inf, r.z);
  checkEquals(nan, r.w);
}

void testNegate() {
  var m = Float32x4(1.0, 2.0, -3.0, -4.0);
  m = -m;
  checkEquals(-1.0, m.x);
  checkEquals(-2.0, m.y);
  checkEquals(3.0, m.z);
  checkEquals(4.0, m.w);

  var n = Float32x4(0.0, -0.0, inf, nan);
  n = -n;
  checkEquals(-0.0, n.x);
  checkEquals(0.0, n.y);
  checkEquals(-inf, n.z);
  checkEquals(nan, n.w);
}

void testSub() {
  var m = Float32x4(-1.0, -2.0, -3.0, -4.0);
  var n = Float32x4(1.0, 2.0, 3.0, 4.0);
  var o = m - n;
  checkEquals(-2.0, o.x);
  checkEquals(-4.0, o.y);
  checkEquals(-6.0, o.z);
  checkEquals(-8.0, o.w);

  var p = Float32x4(-0.0, inf, max, nan);
  var q = Float32x4(0.0, inf, -max, 3.14);
  var r = p - q;
  checkEquals(-0.0, r.x);
  checkEquals(nan, r.y);
  checkEquals(inf, r.z);
  checkEquals(nan, r.w);
}

void testMul() {
  var m = Float32x4(-1.0, -2.0, -3.0, -4.0);
  var n = Float32x4(1.0, 2.0, 3.0, 4.0);
  var o = m * n;
  checkEquals(-1.0, o.x);
  checkEquals(-4.0, o.y);
  checkEquals(-9.0, o.z);
  checkEquals(-16.0, o.w);

  var p = Float32x4(-0.0, inf, max, nan);
  var q = Float32x4(0.0, 0.0, 2.0, 3.14);
  var r = p * q;
  checkEquals(-0.0, r.x);
  checkEquals(nan, r.y);
  checkEquals(inf, r.z);
  checkEquals(nan, r.w);
}

void testDiv() {
  var m = Float32x4(-1.0, -2.0, -3.0, -4.0);
  var n = Float32x4(1.0, 2.0, 3.0, 4.0);
  var o = m / n;
  checkEquals(-1.0, o.x);
  checkEquals(-1.0, o.y);
  checkEquals(-1.0, o.z);
  checkEquals(-1.0, o.w);

  var p = Float32x4(0.0, inf, max, nan);
  var q = Float32x4(-1.0, inf, 0.5, 3.14);
  var r = p / q;
  checkEquals(-0.0, r.x);
  checkEquals(nan, r.y);
  checkEquals(inf, r.z);
  checkEquals(nan, r.w);
}

void testComparison() {
  var m = Float32x4(1.0, 2.0, 0.1, 0.001);
  var n = Float32x4(2.0, 2.0, 0.001, 0.1);
  var cmp;
  cmp = m.lessThan(n);
  Expect.equals(-1, cmp.x);
  Expect.equals(0, cmp.y);
  Expect.equals(0, cmp.z);
  Expect.equals(-1, cmp.w);

  cmp = m.lessThanOrEqual(n);
  Expect.equals(-1, cmp.x);
  Expect.equals(-1, cmp.y);
  Expect.equals(0, cmp.z);
  Expect.equals(-1, cmp.w);

  cmp = m.equal(n);
  Expect.equals(0, cmp.x);
  Expect.equals(-1, cmp.y);
  Expect.equals(0, cmp.z);
  Expect.equals(0, cmp.w);

  cmp = m.notEqual(n);
  Expect.equals(-1, cmp.x);
  Expect.equals(0, cmp.y);
  Expect.equals(-1, cmp.z);
  Expect.equals(-1, cmp.w);

  cmp = m.greaterThanOrEqual(n);
  Expect.equals(0, cmp.x);
  Expect.equals(-1, cmp.y);
  Expect.equals(-1, cmp.z);
  Expect.equals(0, cmp.w);

  cmp = m.greaterThan(n);
  Expect.equals(0, cmp.x);
  Expect.equals(0, cmp.y);
  Expect.equals(-1, cmp.z);
  Expect.equals(0, cmp.w);

  var p = Float32x4(0.0, nan, min, nan);
  var q = Float32x4(-0.0, nan, 0.0, 3.14);

  cmp = p.lessThan(q);
  Expect.equals(0, cmp.x);
  Expect.equals(0, cmp.y);
  Expect.equals(0, cmp.z);
  Expect.equals(0, cmp.w);

  cmp = p.lessThanOrEqual(q);
  Expect.equals(-1, cmp.x);
  Expect.equals(0, cmp.y);
  Expect.equals(0, cmp.z);
  Expect.equals(0, cmp.w);

  cmp = p.equal(q);
  Expect.equals(-1, cmp.x);
  Expect.equals(0, cmp.y);
  Expect.equals(0, cmp.z);
  Expect.equals(0, cmp.w);

  cmp = p.notEqual(q);
  Expect.equals(0, cmp.x);
  Expect.equals(-1, cmp.y);
  Expect.equals(-1, cmp.z);
  Expect.equals(-1, cmp.w);

  cmp = p.greaterThanOrEqual(q);
  Expect.equals(-1, cmp.x);
  Expect.equals(0, cmp.y);
  Expect.equals(-1, cmp.z);
  Expect.equals(0, cmp.w);

  cmp = p.greaterThan(q);
  Expect.equals(0, cmp.x);
  Expect.equals(0, cmp.y);
  Expect.equals(-1, cmp.z);
  Expect.equals(0, cmp.w);
}

void testAbs() {
  var m = Float32x4(1.0, -2.0, 3.0, -4.0);
  m = m.abs();
  checkEquals(1.0, m.x);
  checkEquals(2.0, m.y);
  checkEquals(3.0, m.z);
  checkEquals(4.0, m.w);

  var n = Float32x4(-0.0, 0.0, -inf, nan);
  n = n.abs();
  checkEquals(0.0, n.x);
  checkEquals(0.0, n.y);
  checkEquals(inf, n.z);
  checkEquals(nan, n.w);
}

void testScale() {
  var m = Float32x4(1.0, -2.0, 3.0, -4.0);
  m = m.scale(20.0);
  checkEquals(20.0, m.x);
  checkEquals(-40.0, m.y);
  checkEquals(60.0, m.z);
  checkEquals(-80.0, m.w);

  var n = Float32x4(0.0, max, min, nan);
  var o = n.scale(-2.0);
  checkEquals(-0.0, o.x);
  checkEquals(-inf, o.y);
  checkEquals(-min * 2.0, o.z);
  checkEquals(nan, o.w);
  o = n.scale(-0.5);
  checkEquals(-0.0, o.x);
  checkEquals(-max / 2.0, o.y);
  checkEquals(-0.0, o.z);
  checkEquals(nan, o.w);
  o = n.scale(nan);
  checkEquals(nan, o.x);
  checkEquals(nan, o.y);
  checkEquals(nan, o.z);
  checkEquals(nan, o.w);
  o = n.scale(-0.0);
  checkEquals(-0.0, o.x);
  checkEquals(-0.0, o.y);
  checkEquals(-0.0, o.z);
  checkEquals(nan, o.w);
}

void testClamp() {
  var m = Float32x4(1.0, -2.0, 3.0, -4.0);
  var lo = Float32x4(0.0, 0.0, 0.0, 0.0);
  var hi = Float32x4(2.0, 2.0, 2.0, 2.0);
  m = m.clamp(lo, hi);
  checkEquals(1.0, m.x);
  checkEquals(0.0, m.y);
  checkEquals(2.0, m.z);
  checkEquals(0.0, m.w);

  // No guarantees if one value is `nan` or max < min.
  m = Float32x4(nan, 3.0, -3.0, -4.0);
  lo = Float32x4(0.0, nan, 0.0, 2.0);
  hi = Float32x4(2.0, 2.0, nan, 0.0);
  var r = m.clamp(lo, hi);
  checkOneOf([m.x, lo.x, hi.x], r.x);
  checkOneOf([m.y, lo.y, hi.y], r.y);
  checkOneOf([m.z, lo.z, hi.z], r.z);
  checkOneOf([m.w, lo.w, hi.w], r.w);
}

void testShuffle() {
  var m = Float32x4(1.0, 2.0, 3.0, 4.0);
  var xxxx = m.shuffle(Float32x4.xxxx);
  checkEquals(m.x, xxxx.x);
  checkEquals(m.x, xxxx.y);
  checkEquals(m.x, xxxx.z);
  checkEquals(m.x, xxxx.w);
  var yyyy = m.shuffle(Float32x4.yyyy);
  checkEquals(m.y, yyyy.x);
  checkEquals(m.y, yyyy.y);
  checkEquals(m.y, yyyy.z);
  checkEquals(m.y, yyyy.w);
  var zzzz = m.shuffle(Float32x4.zzzz);
  checkEquals(m.z, zzzz.x);
  checkEquals(m.z, zzzz.y);
  checkEquals(m.z, zzzz.z);
  checkEquals(m.z, zzzz.w);
  var wwww = m.shuffle(Float32x4.wwww);
  checkEquals(m.w, wwww.x);
  checkEquals(m.w, wwww.y);
  checkEquals(m.w, wwww.z);
  checkEquals(m.w, wwww.w);
  var wzyx = m.shuffle(Float32x4.wzyx);
  checkEquals(m.w, wzyx.x);
  checkEquals(m.z, wzyx.y);
  checkEquals(m.y, wzyx.z);
  checkEquals(m.x, wzyx.w);
  var wwzz = m.shuffle(Float32x4.wwzz);
  checkEquals(m.w, wwzz.x);
  checkEquals(m.w, wwzz.y);
  checkEquals(m.z, wwzz.z);
  checkEquals(m.z, wwzz.w);
  var xxyy = m.shuffle(Float32x4.xxyy);
  checkEquals(m.x, xxyy.x);
  checkEquals(m.x, xxyy.y);
  checkEquals(m.y, xxyy.z);
  checkEquals(m.y, xxyy.w);
  var yyww = m.shuffle(Float32x4.yyww);
  checkEquals(m.y, yyww.x);
  checkEquals(m.y, yyww.y);
  checkEquals(m.w, yyww.z);
  checkEquals(m.w, yyww.w);

  double getLane(Float32x4 lanes, int lane) => switch (lane) {
    0 => lanes.x,
    1 => lanes.y,
    2 => lanes.z,
    3 => lanes.w,
    _ => throw UnsupportedError("Test failure, wrong lane number: $lane"),
  };
  for (var i = 0; i < 256; i++) {
    var shuffled = m.shuffle(i);
    checkEquals(getLane(m, i & 3), shuffled.x);
    checkEquals(getLane(m, (i >> 2) & 3), shuffled.y);
    checkEquals(getLane(m, (i >> 4) & 3), shuffled.z);
    checkEquals(getLane(m, (i >> 6) & 3), shuffled.w);
  }
}

void testMin() {
  var m = Float32x4(1.0, 2.0, 3.0, 4.0);
  var n = Float32x4(1.0, 0.0, 2.5, 5.0);
  m = m.min(n);
  checkEquals(1.0, m.x);
  checkEquals(0.0, m.y);
  checkEquals(2.5, m.z);
  checkEquals(4.0, m.w);

  var p = Float32x4(-0.0, -inf, -0.0, nan);
  var q = Float32x4(0.0, -max, -min, 3.5);
  var r = p.min(q);
  checkOneOf([-0.0, 0.0], r.x);
  checkEquals(-inf, r.y);
  checkEquals(-min, r.z);
  checkOneOf([nan, 3.5], r.w);

  r = q.min(p);
  checkOneOf([-0.0, 0.0], r.x);
  checkEquals(-inf, r.y);
  checkEquals(-min, r.z);
  checkOneOf([nan, 3.5], r.w);
}

void testMax() {
  var m = Float32x4(1.0, 2.0, 3.0, 4.0);
  var n = Float32x4(1.0, 0.0, 2.5, 5.0);
  m = m.max(n);
  checkEquals(1.0, m.x);
  checkEquals(2.0, m.y);
  checkEquals(3.0, m.z);
  checkEquals(5.0, m.w);

  var p = Float32x4(-0.0, -inf, -0.0, nan);
  var q = Float32x4(0.0, -max, -min, 3.5);
  var r = p.max(q);
  checkOneOf([-0.0, 0.0], r.x);
  checkEquals(-max, r.y);
  checkEquals(-0.0, r.z);
  checkOneOf([nan, 3.5], r.w);

  r = q.max(p);
  checkOneOf([-0.0, 0.0], r.x);
  checkEquals(-max, r.y);
  checkEquals(-0.0, r.z);
  checkOneOf([nan, 3.5], r.w);
}

void testSqrt() {
  var m = Float32x4(1.0, 4.0, 9.0, 16.0);
  m = m.sqrt();
  checkEquals(1.0, m.x);
  checkEquals(2.0, m.y);
  checkEquals(3.0, m.z);
  checkEquals(4.0, m.w);

  m = Float32x4(0.0, -4.0, inf, nan);
  m = m.sqrt();
  checkEquals(0.0, m.x);
  checkEquals(nan, m.y);
  checkEquals(inf, m.z);
  checkEquals(nan, m.w);

  m = Float32x4(-0.0, -inf, 12224, 12223.999023);
  m = m.sqrt();
  checkEquals(-0.0, m.x);
  checkEquals(nan, m.y);
  Expect.approxEquals(110.56220245361328, m.z, 0.0001);
  Expect.approxEquals(110.5621566772461, m.w, 0.0001);
}

void testReciprocal() {
  var m = Float32x4(1.0, 4.0, 9.0, 16.0);
  m = m.reciprocal();
  Expect.approxEquals(1.0, m.x, 0.001);
  Expect.approxEquals(0.25, m.y, 0.001);
  Expect.approxEquals(0.1111111, m.z, 0.001);
  Expect.approxEquals(0.0625, m.w, 0.001);

  m = Float32x4(0.0, -0.0, inf, nan);
  m = m.reciprocal();
  checkEquals(inf, m.x);
  checkEquals(-inf, m.y);
  checkEquals(0, m.z);
  checkEquals(nan, m.w);
}

void testReciprocalSqrt() {
  var m = Float32x4(1.0, 0.25, 0.111111, 0.0625);
  var n = m.reciprocalSqrt();
  Expect.approxEquals(1.0, n.x, 0.001);
  Expect.approxEquals(2.0, n.y, 0.001);
  Expect.approxEquals(3.0, n.z, 0.001);
  Expect.approxEquals(4.0, n.w, 0.001);

  var o = m.reciprocal().sqrt();
  Expect.approxEquals(o.x, n.x, 0.001);
  Expect.approxEquals(o.y, n.y, 0.001);
  Expect.approxEquals(o.z, n.z, 0.001);
  Expect.approxEquals(o.w, n.w, 0.001);

  m = Float32x4(0.0, -0.0, inf, nan);
  n = m.reciprocalSqrt();
  checkEquals(inf, n.x);
  checkOneOf([nan, -inf], n.y); // One of 1/sqrt(-inf) or sqrt(1/-inf).
  checkEquals(0, n.z);
  checkEquals(nan, n.w);
}

void testSelect() {
  // Technically on `Int32x4`, but only works on `Float32x4`s.
  var m = Int32x4.bool(true, true, false, false);
  var t = Float32x4(1.0, 2.0, 3.0, 4.0);
  var f = Float32x4(5.0, 6.0, 7.0, 8.0);
  var s = m.select(t, f);
  checkEquals(1.0, s.x);
  checkEquals(2.0, s.y);
  checkEquals(7.0, s.z);
  checkEquals(8.0, s.w);
}

void testConversions() {
  var signMask = Int32x4(0x80000000, 0x80000000, 0x80000000, 0x80000000);

  for (var (bits, float) in [
    // Simple values.
    (0x3F800000, 1.0),
    (0x40000000, 2.0),
    (0x40400000, 3.0),
    (0x40800000, 4.0),
    // Special values.
    (0x00000000, 0.0),
    (0x80000000, -0.0),
    (0x00000001, 1.401298464324817e-45),
    (0x80000001, -1.401298464324817e-45),
    (0x007FFFFF, 1.1754942106924411e-38),
    (0x807FFFFF, -1.1754942106924411e-38),
    (0x00800000, 1.1754943508222875e-38),
    (0x80800000, -1.1754943508222875e-38),
    (0x3F7FFFFF, 0.9999999403953552),
    (0xBF7FFFFF, -0.9999999403953552),
    (0x3F800000, 1.0),
    (0xBF800000, -1.0),
    (0x3F800001, 1.0000001192092896),
    (0xBF800001, -1.0000001192092896),
    (0x4AFFFFFF, 8388607.5),
    (0xCAFFFFFF, -8388607.5),
    (0x4B800000, 16777216.0),
    (0xCB800000, -16777216.0),
    (0x7F7FFFFF, 3.4028234663852886e+38),
    (0xFF7FFFFF, -3.4028234663852886e+38),
    (0x7F800000, inf),
    (0xFF800000, -inf),
    (0x7FC00000, nan), // Quiet NaN
    (0xFFC00000, -nan), // Negative Quiet NaN.
    (0x7F800001, nan), // Signaling NaN
    (0x7F800001, -nan), // Signaling NaN
    (0x3F7FFFFF, 0.9999999403953552),
    (0xBF7FFFFF, -0.9999999403953552),
    (0x4B000001, 8388609.0),
    (0xCB000001, -8388609.0),
    (0x4B7FFFFF, 16777215.0),
    (0xCB7FFFFF, -16777215.0),
  ]) {
    var b = Int32x4(bits, bits, bits, bits);
    var f = Float32x4.fromInt32x4Bits(b);
    checkEquals(float, f.x);
    checkEquals(float, f.y);
    checkEquals(float, f.z);
    checkEquals(float, f.w);
    // Flip sign using bit mask.
    bits ^= 0x80000000;
    b = Int32x4(bits, bits, bits, bits);
    f = Float32x4.fromInt32x4Bits(b);
    checkEquals(-float, f.x);
    checkEquals(-float, f.y);
    checkEquals(-float, f.z);
    checkEquals(-float, f.w);
  }
}

void testSetters() {
  var f = Float32x4.zero();
  checkEquals(0.0, f.x);
  checkEquals(0.0, f.y);
  checkEquals(0.0, f.z);
  checkEquals(0.0, f.w);
  f = f.withX(4.0);
  checkEquals(4.0, f.x);
  f = f.withY(3.0);
  checkEquals(3.0, f.y);
  f = f.withZ(2.0);
  checkEquals(2.0, f.z);
  f = f.withW(1.0);
  checkEquals(1.0, f.w);
  f = Float32x4.zero();
  f = f.withX(4.0).withZ(2.0).withW(1.0).withY(3.0);
  checkEquals(4.0, f.x);
  checkEquals(3.0, f.y);
  checkEquals(2.0, f.z);
  checkEquals(1.0, f.w);
}

void testSplat() {
  for (var v in [2.0, 0.0, -0.0, inf, -inf, nan, max, min]) {
    var f = Float32x4.splat(v);
    checkEquals(v, f.x);
    checkEquals(v, f.y);
    checkEquals(v, f.z);
    checkEquals(v, f.w);
  }
}

void testZeroConstructor() {
  var f = Float32x4.zero();
  checkEquals(0.0, f.x);
  checkEquals(0.0, f.y);
  checkEquals(0.0, f.z);
  checkEquals(0.0, f.w);
}

void testConstructorAndGetters() {
  var f = Float32x4(1.0, 2.0, 3.0, 4.0);
  checkEquals(1.0, f.x);
  checkEquals(2.0, f.y);
  checkEquals(3.0, f.z);
  checkEquals(4.0, f.w);
}

void testBadArguments() {
  // Checks that non-double values are not accepted.
  // The compiler should insert a dynamic downcast to `double` for each
  // `dynamic`-typed argument. This test checks that no optimization gets
  // in the way of that test.

  dynamic dynamicValue = null;
  Expect.throwsTypeError(() => Float32x4(dynamicValue, 2.0, 3.0, 4.0));
  Expect.throwsTypeError(() => Float32x4(1.0, dynamicValue, 3.0, 4.0));
  Expect.throwsTypeError(() => Float32x4(1.0, 2.0, dynamicValue, 4.0));
  Expect.throwsTypeError(() => Float32x4(1.0, 2.0, 3.0, dynamicValue));

  dynamicValue = "foo";
  Expect.throwsTypeError(() => Float32x4(dynamicValue, 2.0, 3.0, 4.0));
  Expect.throwsTypeError(() => Float32x4(1.0, dynamicValue, 3.0, 4.0));
  Expect.throwsTypeError(() => Float32x4(1.0, 2.0, dynamicValue, 4.0));
  Expect.throwsTypeError(() => Float32x4(1.0, 2.0, 3.0, dynamicValue));
}

void testSpecialValues() {
  // Pairs of double values and (a double representation of) their closest
  // 32-bit floating point value.
  // The second value is what the first value is rounded to when converted
  // to 32-bit float.
  var pairs = [
    // Values that are precisely representable as float-32.
    for (var f32 in [
      0.0,
      1.0,
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
      4294967296.0,
      inf,
      nan,
    ])
      (f32, f32),
    // Values that round when converted.
    (5e-324, 0.0),
    (2.225073858507201e-308, 0.0),
    (2.2250738585072014e-308, 0.0),
    (0.9999999999999999, 1.0),
    (1.0000000000000002, 1.0),
    (4294967295.0, 4294967296.0),
    (4503599627370495.5, 4503599627370496.0),
    (9007199254740992.0, 9007199254740992.0),
    (1.7976931348623157e+308, inf),
    (0.49999999999999994, 0.5),
    (4503599627370497.0, 4503599627370496.0),
    (9007199254740991.0, 9007199254740992.0),
  ];

  var allTests = [
    ...pairs,
    // Add negative variant of every pair.
    for (var (d, f) in pairs) (-d, -f),
  ];

  for (var (input, expected) in allTests) {
    var f;
    f = Float32x4(input, 2.0, 3.0, 4.0);
    checkEquals(expected, f.x);
    checkEquals(2.0, f.y);
    checkEquals(3.0, f.z);
    checkEquals(4.0, f.w);

    f = Float32x4(1.0, input, 3.0, 4.0);
    checkEquals(1.0, f.x);
    checkEquals(expected, f.y);
    checkEquals(3.0, f.z);
    checkEquals(4.0, f.w);

    f = Float32x4(1.0, 2.0, input, 4.0);
    checkEquals(1.0, f.x);
    checkEquals(2.0, f.y);
    checkEquals(expected, f.z);
    checkEquals(4.0, f.w);

    f = Float32x4(1.0, 2.0, 3.0, input);
    checkEquals(1.0, f.x);
    checkEquals(2.0, f.y);
    checkEquals(3.0, f.z);
    checkEquals(expected, f.w);
  }
}

void main() {
  for (int i = 0; i < 20; i++) {
    testConstructorAndGetters();
    testSetters();
    testSplat();
    testZeroConstructor();
    testAdd();
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

void checkEquals(double expected, double actual) {
  if (!_sameDouble(expected, actual)) {
    Expect.fail("Not equal. Expected: $expected, actual: $actual");
  }
}

void checkOneOf(List<double> possibleValues, double actual) {
  if (!possibleValues.any((v) => _sameDouble(v, actual))) {
    Expect.fail(
      "Not equal. Expected one of: ${possibleValues.join(', ')}, "
      "actual: $actual",
    );
  }
}

bool _sameDouble(double v1, double v2) {
  if (v1 == v2) {
    // False positive for 0.0 and -0.0.
    return v1.isNegative == v2.isNegative;
  }
  // False negative for NaN.
  return v1.isNaN && v2.isNaN;
}
