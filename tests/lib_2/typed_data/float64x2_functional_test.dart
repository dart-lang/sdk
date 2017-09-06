// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation
// VMOptions=--no-intrinsify

library float64x2_functional_test;

import 'dart:typed_data';
import "package:expect/expect.dart";

testConstructor() {
  var a = new Float64x2(1.0, 2.0);
  Expect.equals(1.0, a.x);
  Expect.equals(2.0, a.y);
  var b = new Float64x2.splat(1.0);
  Expect.equals(1.0, b.x);
  Expect.equals(1.0, b.y);
  var c = new Float64x2.zero();
  Expect.equals(0.0, c.x);
  Expect.equals(0.0, c.y);
}

testCastConstructor() {
  var a = new Float32x4(9.0, 8.0, 7.0, 6.0);
  var b = new Float64x2.fromFloat32x4(a);
  Expect.equals(9.0, b.x);
  Expect.equals(8.0, b.y);
  var c = new Float32x4.fromFloat64x2(b);
  Expect.equals(9.0, c.x);
  Expect.equals(8.0, c.y);
  Expect.equals(0.0, c.z);
  Expect.equals(0.0, c.w);
}

testLaneSetter() {
  var a = new Float64x2.zero();
  Expect.equals(0.0, a.x);
  Expect.equals(0.0, a.y);
  var b = a.withX(99.0);
  Expect.equals(0.0, a.x);
  Expect.equals(0.0, a.y);
  Expect.equals(99.0, b.x);
  Expect.equals(0.0, b.y);
  var c = a.withY(88.0);
  Expect.equals(0.0, a.x);
  Expect.equals(0.0, a.y);
  Expect.equals(0.0, c.x);
  Expect.equals(88.0, c.y);
  var d = c.withX(11.0);
  Expect.equals(0.0, c.x);
  Expect.equals(88.0, c.y);
  Expect.equals(11.0, d.x);
  Expect.equals(88.0, d.y);
}

testNegate() {
  var m = new Float64x2(1.0, -2.0);
  var o = -m;
  Expect.equals(-1.0, o.x);
  Expect.equals(2.0, o.y);
}

testAdd() {
  var m = new Float64x2(1.0, -2.0);
  var n = new Float64x2(1.0, 2.0);
  var o = m + n;
  Expect.equals(2.0, o.x);
  Expect.equals(0.0, o.y);
}

testSub() {
  var m = new Float64x2(1.5, -2.0);
  var n = new Float64x2(1.0, 2.0);
  var o = m - n;
  Expect.equals(0.5, o.x);
  Expect.equals(-4.0, o.y);
}

testMul() {
  var m = new Float64x2(1.0, -2.0);
  var n = new Float64x2(2.0, 2.0);
  var o = m * n;
  Expect.equals(2.0, o.x);
  Expect.equals(-4.0, o.y);
}

testDiv() {
  var m = new Float64x2(1.0, -2.0);
  var n = new Float64x2(2.0, 2.0);
  var o = m / n;
  Expect.equals(0.5, o.x);
  Expect.equals(-1.0, o.y);
}

testScale() {
  var m = new Float64x2(1.0, 0.5);
  var n = m.scale(2.0);
  Expect.equals(2.0, n.x);
  Expect.equals(1.0, n.y);
}

testAbs() {
  var m = new Float64x2(1.0, -0.5).abs();
  var n = new Float64x2(-2.0, 1.0).abs();
  Expect.equals(1.0, m.x);
  Expect.equals(0.5, m.y);
  Expect.equals(2.0, n.x);
  Expect.equals(1.0, n.y);
}

testClamp() {
  var m = new Float64x2(1.0, -2.0);
  var lo = new Float64x2(0.0, 0.5);
  var hi = new Float64x2(2.0, 2.0);
  m = m.clamp(lo, hi);
  Expect.equals(1.0, m.x);
  Expect.equals(0.5, m.y);
}

testSignMask() {
  var m = new Float64x2(-1.0, -0.0);
  Expect.equals(3, m.signMask);
  m = new Float64x2(0.0, 0.0);
  Expect.equals(0, m.signMask);
  m = new Float64x2(-1.0, 0.0);
  Expect.equals(1, m.signMask);
  m = new Float64x2(1.0, -0.0);
  Expect.equals(2, m.signMask);
}

testMin() {
  var m = new Float64x2(0.0, -99.0);
  var n = new Float64x2(-1.0, -1.0);
  var o = m.min(n);
  Expect.equals(-1.0, o.x);
  Expect.equals(-99.0, o.y);
}

testMax() {
  var m = new Float64x2(0.5, -99.0);
  var n = new Float64x2(-1.0, -1.0);
  var o = m.max(n);
  Expect.equals(0.5, o.x);
  Expect.equals(-1.0, o.y);
}

testSqrt() {
  var m = new Float64x2(9.0, 16.0);
  var o = m.sqrt();
  Expect.equals(3.0, o.x);
  Expect.equals(4.0, o.y);
}

testTypedList() {
  var m = new Float64x2List(2);
  var n = m[0];
  Expect.equals(0.0, n.x);
  Expect.equals(0.0, n.y);
  n = n.withX(1.0);
  n = n.withY(2.0);
  m[0] = n;
  n = n.withX(99.0);
  Expect.equals(99.0, n.x);
  Expect.equals(1.0, m[0].x);
  Expect.equals(2.0, m[0].y);
}

testTypedListFromList() {
  var l = [new Float64x2(1.0, 2.0), new Float64x2(3.0, 4.0)];
  var m = new Float64x2List.fromList(l);
  Expect.equals(2, m.length);
  Expect.equals(16, m.elementSizeInBytes);
  Expect.equals(32, m.lengthInBytes);
  Expect.equals(1.0, m[0].x);
  Expect.equals(2.0, m[0].y);
  Expect.equals(3.0, m[1].x);
  Expect.equals(4.0, m[1].y);
}

testTypedListFromTypedList() {
  var l = new Float64x2List(2);
  l[0] = new Float64x2(1.0, 2.0);
  l[1] = new Float64x2(3.0, 4.0);
  Expect.equals(2, l.length);
  Expect.equals(16, l.elementSizeInBytes);
  Expect.equals(32, l.lengthInBytes);
  Expect.equals(1.0, l[0].x);
  Expect.equals(2.0, l[0].y);
  Expect.equals(3.0, l[1].x);
  Expect.equals(4.0, l[1].y);
  var m = new Float64x2List.fromList(l);
  Expect.equals(2, m.length);
  Expect.equals(16, m.elementSizeInBytes);
  Expect.equals(32, m.lengthInBytes);
  Expect.equals(2, m.length);
  Expect.equals(1.0, m[0].x);
  Expect.equals(2.0, m[0].y);
  Expect.equals(3.0, m[1].x);
  Expect.equals(4.0, m[1].y);
}

testTypedListView() {
  var l = [1.0, 2.0, 3.0, 4.0];
  Expect.equals(4, l.length);
  var fl = new Float64List.fromList(l);
  Expect.equals(4, fl.length);
  var m = new Float64x2List.view(fl.buffer);
  Expect.equals(2, m.length);
  Expect.equals(1.0, m[0].x);
  Expect.equals(2.0, m[0].y);
  Expect.equals(3.0, m[1].x);
  Expect.equals(4.0, m[1].y);
}

testTypedListFullView() {
  var l = [new Float64x2(1.0, 2.0), new Float64x2(3.0, 4.0)];
  var m = new Float64x2List.fromList(l);
  Expect.equals(2, m.length);
  Expect.equals(1.0, m[0].x);
  Expect.equals(2.0, m[0].y);
  Expect.equals(3.0, m[1].x);
  Expect.equals(4.0, m[1].y);
  // Create a view which spans the entire buffer.
  var n = new Float64x2List.view(m.buffer);
  Expect.equals(2, n.length);
  Expect.equals(1.0, n[0].x);
  Expect.equals(2.0, n[0].y);
  Expect.equals(3.0, n[1].x);
  Expect.equals(4.0, n[1].y);
  // Create a view which spans the entire buffer by specifying length.
  var o = new Float64x2List.view(m.buffer, 0, 2);
  Expect.equals(2, o.length);
  Expect.equals(1.0, o[0].x);
  Expect.equals(2.0, o[0].y);
  Expect.equals(3.0, o[1].x);
  Expect.equals(4.0, o[1].y);
}

testSubList() {
  var l = [new Float64x2(1.0, 2.0), new Float64x2(3.0, 4.0)];
  var m = new Float64x2List.fromList(l);
  var n = m.sublist(0, 1);
  Expect.equals(1, n.length);
  Expect.equals(1.0, n[0].x);
  Expect.equals(2.0, n[0].y);
  var o = m.sublist(1, 2);
  Expect.equals(1, o.length);
  Expect.equals(3.0, o[0].x);
  Expect.equals(4.0, o[0].y);
}

testSubView() {
  var l = [new Float64x2(1.0, 2.0), new Float64x2(3.0, 4.0)];
  var m = new Float64x2List.fromList(l);
  var n = new Float64x2List.view(m.buffer, 16, 1);
  Expect.equals(1, n.length);
  Expect.equals(16, n.offsetInBytes);
  Expect.equals(16, n.lengthInBytes);
  Expect.equals(3.0, n[0].x);
  Expect.equals(4.0, n[0].y);
  var o = new Float64x2List.view(m.buffer, 0, 1);
  Expect.equals(1, o.length);
  Expect.equals(0, o.offsetInBytes);
  Expect.equals(16, o.lengthInBytes);
  Expect.equals(1.0, o[0].x);
  Expect.equals(2.0, o[0].y);
}

main() {
  for (int i = 0; i < 20; i++) {
    testConstructor();
    testCastConstructor();
    testLaneSetter();
    testNegate();
    testAdd();
    testSub();
    testMul();
    testDiv();
    testScale();
    testAbs();
    testClamp();
    testSignMask();
    testMin();
    testMax();
    testSqrt();
    testTypedList();
    testTypedListFromList();
    testTypedListFromTypedList();
    testTypedListView();
    testTypedListFullView();
    testSubList();
    testSubView();
  }
}
