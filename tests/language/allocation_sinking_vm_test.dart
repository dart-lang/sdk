// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test allocation sinking optimization.

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

main() {
  var c = new C(new Point(0.1, 0.2));

  // Compute initial values.
  final x0 = test1(c, 11.11, 22.22);
  final y0 = testForwardingThroughEffects(c, 11.11, 22.22);
  final z0 = testIdentity(c.p);

  // Force optimization.
  for (var i = 0; i < 10000; i++) {
    test1(c, i.toDouble(), i.toDouble());
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
}
