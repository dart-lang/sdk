// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test allocation sinking optimization.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import 'dart:typed_data';
import 'package:expect/expect.dart';

class Point {
  var x, y;

  Point(this.x, this.y);

  operator * (other) {
    return x * other.x + y * other.y;
  }
}

class C {
  var p;
  C(this.p);
}


class Pointx4 {
  var x, y;

  Pointx4(this.x, this.y);

  operator * (other) {
    return x * other.x + y * other.y;
  }
}

class Cx4 {
  var p;
  Cx4(this.p);
}

class D {
  var p;
  D(this.p);
}

// Class that is used to capture materialized Point object with * operator.
class F {
  var p;
  var val;

  F(this.p);

  operator * (other) {
    Expect.isTrue(other is Point);
    Expect.equals(42.0, other.x);
    Expect.equals(0.5, other.y);

    if (val == null) {
      val = other;
    } else {
      Expect.isTrue(identical(val, other));
    }

    return this.p * other;
  }
}

test1(c, x, y) {
  var a = new Point(x - 0.5, y + 0.5);
  var b = new Point(x + 0.5, y + 0.8);
  var d = new Point(c.p * a, c.p * b);
  return d * d;
}

test1x4(c, x, y, z, w) {
  var a = new Pointx4(x - z, y + w);
  var b = new Pointx4(x + w, y + z);
  var d = new Pointx4(c.p * a, c.p * b);
  return d * d;
}

effects() {
  // This function should not be inlinable.
  try { } catch (e) { }
}

testForwardingThroughEffects(c, x, y) {
  var a = new Point(x - 0.5, y + 0.5);
  var b = new Point(x - 0.5, y - 0.8);
  var d = new Point(c.p * a, c.p * b);
  // Effects can't affect neither a, b, nor d because they do not escape.
  effects();
  effects();
  return ((a == null) ? 0.0 : 0.1) + (d * d);
}

testIdentity(x) {
  var y = new Point(42.0, 0.5);
  var z = y;
  return x * y + x * z;
}

class PointP<T> {
  var x, y;

  PointP(this.x, this.y);

  operator * (other) {
    return x * other.x + y * other.y;
  }
}

foo2() => new PointP<int>(1, 3) * new PointP<num>(5, 6);

class A<T> {
  var x, y;
}

foo3(x) {
  // Test materialization of type arguments.
  var a = new A<int>();
  a.x = x;
  a.y = x;
  if (x is int) return a.x + a.y;
  Expect.isFalse(a is A<double>);
  Expect.isTrue(a is A<int>);
  Expect.isTrue(a is A);
  return a.x - a.y;
}

class WithFinal {
  final _x;
  WithFinal(this._x);
}

testInitialValueForFinalField(x) {
  new WithFinal(x);
}

testFinalField() {
  for (var i = 0; i < 100; i++) {
   testInitialValueForFinalField(1);
  }
}

class V {
  var x = 0;
}

test_vm_field() {
  var obj;
  inner() => obj.x = 42;
  var a = new V();
  obj = a;
  var t1 = a.x;
  var t2 = inner();
  return a.x + t1 + t2;
}

testVMField() {
  Expect.equals(84, test_vm_field());
  for (var i = 0; i < 100; i++) test_vm_field();
  Expect.equals(84, test_vm_field());
}

class CompoundA {
  var b;
  CompoundA(this.b);
}

class CompoundB {
  var c;
  CompoundB(this.c);
}

class CompoundC {
  var d;
  var root;
  CompoundC(this.d);
}

class NoopSink {
  const NoopSink();
  call(val) { }
}

testCompound1() {
  f(d, [sink = const NoopSink()]) {
    var c = new CompoundC(d);
    var a = new CompoundA(new CompoundB(c));
    sink(a);
    return c.d;
  }

  Expect.equals(0.1, f(0.1));
  for (var i = 0; i < 100; i++) f(0.1);
  Expect.equals(0.1, f(0.1));
  Expect.equals(0.1, f(0.1, (val) {
    Expect.isTrue(val is CompoundA);
    Expect.isTrue(val.b is CompoundB);
    Expect.isTrue(val.b.c is CompoundC);
    Expect.isNull(val.b.c.root);
    Expect.equals(0.1, val.b.c.d);
  }));
}


testCompound2() {
  f(d, [sink = const NoopSink()]) {
    var c = new CompoundC(d);
    var a = new CompoundA(new CompoundB(c));
    c.root = a;
    sink(a);
    return c.d;
  }

  Expect.equals(0.1, f(0.1));
  for (var i = 0; i < 100; i++) f(0.1);
  Expect.equals(0.1, f(0.1));
  Expect.equals(0.1, f(0.1, (val) {
    Expect.isTrue(val is CompoundA);
    Expect.isTrue(val.b is CompoundB);
    Expect.isTrue(val.b.c is CompoundC);
    Expect.equals(val, val.b.c.root);
    Expect.equals(0.1, val.b.c.d);
  }));
}


testCompound3() {
  f(d, [sink = const NoopSink()]) {
    var c = new CompoundC(d);
    c.root = c;
    sink(c);
    return c.d;
  }

  Expect.equals(0.1, f(0.1));
  for (var i = 0; i < 100; i++) f(0.1);
  Expect.equals(0.1, f(0.1));
  Expect.equals(0.1, f(0.1, (val) {
    Expect.isTrue(val is CompoundC);
    Expect.equals(val, val.root);
    Expect.equals(0.1, val.d);
  }));
}


testCompound4() {
  f(d, [sink = const NoopSink()]) {
    var c = new CompoundC(d);
    c.root = c;
    for (var i = 0; i < 10; i++) {
      c.d += 1.0;
    }
    sink(c);
    return c.d - 1.0 * 10;
  }

  Expect.equals(1.0, f(1.0));
  for (var i = 0; i < 100; i++) f(1.0);
  Expect.equals(1.0, f(1.0));
  Expect.equals(1.0, f(1.0, (val) {
    Expect.isTrue(val is CompoundC);
    Expect.equals(val, val.root);
    Expect.equals(11.0, val.d);
  }));
}


main() {
  var c = new C(new Point(0.1, 0.2));

  // Compute initial values.
  final x0 = test1(c, 11.11, 22.22);
  var fc = new Cx4(new Pointx4(new Float32x4(1.0, 1.0, 1.0, 1.0),
                               new Float32x4(1.0, 1.0, 1.0, 1.0)));
  final fx0 = test1x4(fc, new Float32x4(1.0, 1.0, 1.0, 1.0),
                          new Float32x4(1.0, 1.0, 1.0, 1.0),
                          new Float32x4(1.0, 1.0, 1.0, 1.0),
                          new Float32x4(1.0, 1.0, 1.0, 1.0));
  final y0 = testForwardingThroughEffects(c, 11.11, 22.22);
  final z0 = testIdentity(c.p);

  // Force optimization.
  for (var i = 0; i < 100; i++) {
    test1(c, i.toDouble(), i.toDouble());
    test1x4(fc, new Float32x4(1.0, 1.0, 1.0, 1.0),
                new Float32x4(1.0, 1.0, 1.0, 1.0),
                new Float32x4(1.0, 1.0, 1.0, 1.0),
                new Float32x4(1.0, 1.0, 1.0, 1.0));
    testForwardingThroughEffects(c, i.toDouble(), i.toDouble());
    testIdentity(c.p);
    foo2();
    Expect.equals(10, foo3(5));
  }
  Expect.equals(0.0, foo3(0.5));

  // Test returned value after optimization.
  final x1 = test1(c, 11.11, 22.22);
  final y1 = testForwardingThroughEffects(c, 11.11, 22.22);

  // Test returned value after deopt.
  final x2 = test1(new D(c.p), 11.11, 22.22);
  final y2 = testForwardingThroughEffects(new D(c.p), 11.11, 22.22);

  Expect.equals(6465, (x0 * 100).floor());
  Expect.equals(6465, (x1 * 100).floor());
  Expect.equals(6465, (x2 * 100).floor());
  Expect.equals(x0, x1);
  Expect.equals(x0, x2);

  Expect.equals(6008, (y0 * 100).floor());
  Expect.equals(6008, (y1 * 100).floor());
  Expect.equals(6008, (y2 * 100).floor());
  Expect.equals(y0, y1);
  Expect.equals(y0, y2);

  // Test that identity of materialized objects is preserved correctly and
  // no copies are materialized.
  final z1 = testIdentity(c.p);
  final z2 = testIdentity(new F(c.p));
  Expect.equals(z0, z1);
  Expect.equals(z0, z2);

  testFinalField();
  testVMField();
  testCompound1();
  testCompound2();
  testCompound3();
  testCompound4();
}
