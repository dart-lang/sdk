// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library rect_test;

import 'dart:math';
import 'package:unittest/unittest.dart';

main() {
  Rectangle createRectangle(List<num> a) {
    return a != null ? new Rectangle(a[0], a[1], a[2] - a[0], a[3] - a[1])
        : null;
  }

  test('construction', () {
    var r0 = new Rectangle(10, 20, 30, 40);
    expect(r0.toString(), 'Rectangle (10, 20) 30 x 40');
    expect(r0.right, 40);
    expect(r0.bottom, 60);

    var r1 = new Rectangle.fromPoints(r0.topLeft, r0.bottomRight);
    expect(r1, r0);

    var r2 = new Rectangle.fromPoints(r0.bottomRight, r0.topLeft);
    expect(r2, r0);
  });

  test('intersection', () {
    var tests = [
        [[10, 10, 20, 20], [15, 15, 25, 25], [15, 15, 20, 20]],
        [[10, 10, 20, 20], [20, 0, 30, 10], [20, 10, 20, 10]],
        [[0, 0, 1, 1], [10, 11, 12, 13], null],
        [[11, 12, 98, 99], [22, 23, 34, 35], [22, 23, 34, 35]]];

    for (var test in tests) {
      var r0 = createRectangle(test[0]);
      var r1 = createRectangle(test[1]);
      var expected = createRectangle(test[2]);

      expect(r0.intersection(r1), expected);
      expect(r1.intersection(r0), expected);
    }
  });

  test('intersects', () {
    var r0 = new Rectangle(10, 10, 20, 20);
    var r1 = new Rectangle(15, 15, 25, 25);
    var r2 = new Rectangle(0, 0, 1, 1);

    expect(r0.intersects(r1), isTrue);
    expect(r1.intersects(r0), isTrue);

    expect(r0.intersects(r2), isFalse);
    expect(r2.intersects(r0), isFalse);
  });

  test('union', () {
    var tests = [
        [[10, 10, 20, 20], [15, 15, 25, 25], [10, 10, 25, 25]],
        [[10, 10, 20, 20], [20, 0, 30, 10], [10, 0, 30, 20]],
        [[0, 0, 1, 1], [10, 11, 12, 13], [0, 0, 12, 13]],
        [[11, 12, 98, 99], [22, 23, 34, 35], [11, 12, 98, 99]]];

    for (var test in tests) {
      var r0 = createRectangle(test[0]);
      var r1 = createRectangle(test[1]);
      var expected = createRectangle(test[2]);

      expect(r0.union(r1), expected);
      expect(r1.union(r0), expected);
    }
  });

  test('containsRectangle', () {
    var r = new Rectangle(-10, 0, 20, 10);
    expect(r.contains(r), isTrue);

    expect(r.contains(
        new Rectangle(double.NAN, double.NAN, double.NAN, double.NAN)), isFalse);

    var r2 = new Rectangle(0, 2, 5, 5);
    expect(r.contains(r2), isTrue);
    expect(r2.contains(r), isFalse);

    r2 = new Rectangle(-11, 2, 5, 5);
    expect(r.contains(r2), isFalse);
    r2 = new Rectangle(0, 2, 15, 5);
    expect(r.contains(r2), isFalse);
    r2 = new Rectangle(0, 2, 5, 10);
    expect(r.contains(r2), isFalse);
    r2 = new Rectangle(0, 0, 5, 10);
    expect(r.contains(r2), isTrue);
  });

  test('containsPoint', () {
    var r = new Rectangle(20, 40, 60, 80);

    // Test middle.
    expect(r.containsPoint(new Point(50, 80)), isTrue);

    // Test edges.
    expect(r.containsPoint(new Point(20, 40)), isTrue);
    expect(r.containsPoint(new Point(50, 40)), isTrue);
    expect(r.containsPoint(new Point(80, 40)), isTrue);
    expect(r.containsPoint(new Point(80, 80)), isTrue);
    expect(r.containsPoint(new Point(80, 120)), isTrue);
    expect(r.containsPoint(new Point(50, 120)), isTrue);
    expect(r.containsPoint(new Point(20, 120)), isTrue);
    expect(r.containsPoint(new Point(20, 80)), isTrue);

    // Test outside.
    expect(r.containsPoint(new Point(0, 0)), isFalse);
    expect(r.containsPoint(new Point(50, 0)), isFalse);
    expect(r.containsPoint(new Point(100, 0)), isFalse);
    expect(r.containsPoint(new Point(100, 80)), isFalse);
    expect(r.containsPoint(new Point(100, 160)), isFalse);
    expect(r.containsPoint(new Point(50, 160)), isFalse);
    expect(r.containsPoint(new Point(0, 160)), isFalse);
    expect(r.containsPoint(new Point(0, 80)), isFalse);
  });

  test('ceil', () {
    var rect = new Rectangle(11.4, 26.6, 17.8, 9.2);
    expect(rect.ceil(), new Rectangle(12.0, 27.0, 18.0, 10.0));
  });

  test('floor', () {
    var rect = new Rectangle(11.4, 26.6, 17.8, 9.2);
    expect(rect.floor(), new Rectangle(11.0, 26.0, 17.0, 9.0));
  });

  test('round', () {
    var rect = new Rectangle(11.4, 26.6, 17.8, 9.2);
    expect(rect.round(), new Rectangle(11.0, 27.0, 18.0, 9.0));
  });

  test('truncate', () {
    var rect = new Rectangle(11.4, 26.6, 17.8, 9.2);
    var b = rect.truncate();
    expect(b, new Rectangle(11, 26, 17, 9));

    expect(b.left is int, isTrue);
    expect(b.top is int, isTrue);
    expect(b.width is int, isTrue);
    expect(b.height is int, isTrue);
  });

  test('hashCode', () {
    var a = new Rectangle(0, 1, 2, 3);
    var b = new Rectangle(0, 1, 2, 3);
    expect(a.hashCode, b.hashCode);

    var c = new Rectangle(1, 0, 2, 3);
    expect(a.hashCode == c.hashCode, isFalse);
  });
}
