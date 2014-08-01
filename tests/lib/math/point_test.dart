// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library point_test;

import 'dart:math';
import 'package:unittest/unittest.dart';

main() {
  test('constructor', () {
    var point = new Point(0, 0);
    expect(point.x, 0);
    expect(point.y, 0);
    expect('$point', 'Point(0, 0)');
  });

  test('constructor X', () {
    var point = new Point<int>(10, 0);
    expect(point.x, 10);
    expect(point.y, 0);
    expect('$point', 'Point(10, 0)');
  });

  test('constructor X Y', () {
    var point = new Point<int>(10, 20);
    expect(point.x, 10);
    expect(point.y, 20);
    expect('$point', 'Point(10, 20)');
  });

  test('constructor X Y double', () {
    var point = new Point<double>(10.5, 20.897);
    expect(point.x, 10.5);
    expect(point.y, 20.897);
    expect('$point', 'Point(10.5, 20.897)');
  });

  test('constructor X Y NaN', () {
    var point = new Point(double.NAN, 1000);
    expect(point.x, isNaN);
    expect(point.y, 1000);
    expect('$point', 'Point(NaN, 1000)');
  });

  test('squaredDistanceTo', () {
    var a = new Point(7, 11);
    var b = new Point(3, -1);
    expect(a.squaredDistanceTo(b), 160);
    expect(b.squaredDistanceTo(a), 160);
  });

  test('distanceTo', () {
    var a = new Point(-2, -3);
    var b = new Point(2, 0);
    expect(a.distanceTo(b), 5);
    expect(b.distanceTo(a), 5);
  });

  test('subtract', () {
    var a = new Point(5, 10);
    var b = new Point(2, 50);
    expect(a - b, new Point(3, -40));
  });

  test('add', () {
    var a = new Point(5, 10);
    var b = new Point(2, 50);
    expect(a + b, new Point(7, 60));
  });

  test('hashCode', () {
    var a = new Point(0, 1);
    var b = new Point(0, 1);
    expect(a.hashCode, b.hashCode);

    var c = new Point(1, 0);
    expect(a.hashCode == c.hashCode, isFalse);
  });

  test('magnitute', () {
    var a = new Point(5, 10);
    var b = new Point(0, 0);
    expect(a.magnitude, a.distanceTo(b));
    expect(b.magnitude, 0);

    var c = new Point(-5, -10);
    expect(c.magnitude, a.distanceTo(b));
  });
}
