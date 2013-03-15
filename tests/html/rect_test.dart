// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library rect_test;

import 'dart:html';
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';

main() {
  useHtmlConfiguration();

  Rect createRect(List<num> a) {
    return a != null ? new Rect(a[0], a[1], a[2] - a[0], a[3] - a[1]) : null;
  }

  test('construction', () {
    var r0 = new Rect(10, 20, 30, 40);
    expect(r0.toString(), '(10, 20, 30, 40)');
    expect(r0.right, 40);
    expect(r0.bottom, 60);

    var r1 = new Rect.fromPoints(r0.topLeft, r0.bottomRight);
    expect(r1, r0);

    var r2 = new Rect.fromPoints(r0.bottomRight, r0.topLeft);
    expect(r2, r0);
  });

  test('intersection', () {
    var tests = [
        [[10, 10, 20, 20], [15, 15, 25, 25], [15, 15, 20, 20]],
        [[10, 10, 20, 20], [20, 0, 30, 10], [20, 10, 20, 10]],
        [[0, 0, 1, 1], [10, 11, 12, 13], null],
        [[11, 12, 98, 99], [22, 23, 34, 35], [22, 23, 34, 35]]];

    for (var test in tests) {
      var r0 = createRect(test[0]);
      var r1 = createRect(test[1]);
      var expected = createRect(test[2]);

      expect(r0.intersection(r1), expected);
      expect(r1.intersection(r0), expected);
    }
  });

  test('intersects', () {
    var r0 = new Rect(10, 10, 20, 20);
    var r1 = new Rect(15, 15, 25, 25);
    var r2 = new Rect(0, 0, 1, 1);

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
      var r0 = createRect(test[0]);
      var r1 = createRect(test[1]);
      var expected = createRect(test[2]);

      expect(r0.union(r1), expected);
      expect(r1.union(r0), expected);
    }
  });

  test('containsRect', () {
    var r = new Rect(-10, 0, 20, 10);
    expect(r.containsRect(r), isTrue);

    expect(r.containsRect(
        new Rect(double.NAN, double.NAN, double.NAN, double.NAN)), isFalse);

    var r2 = new Rect(0, 2, 5, 5);
    expect(r.containsRect(r2), isTrue);
    expect(r2.containsRect(r), isFalse);

    r2 = new Rect(-11, 2, 5, 5);
    expect(r.containsRect(r2), isFalse);
    r2 = new Rect(0, 2, 15, 5);
    expect(r.containsRect(r2), isFalse);
    r2 = new Rect(0, 2, 5, 10);
    expect(r.containsRect(r2), isFalse);
    r2 = new Rect(0, 0, 5, 10);
    expect(r.containsRect(r2), isTrue);
  });

  test('containsPoint', () {
    var r = new Rect(20, 40, 60, 80);

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
    var rect = new Rect(11.4, 26.6, 17.8, 9.2);
    expect(rect.ceil(), new Rect(12.0, 27.0, 18.0, 10.0));
  });

  test('floor', () {
    var rect = new Rect(11.4, 26.6, 17.8, 9.2);
    expect(rect.floor(), new Rect(11.0, 26.0, 17.0, 9.0));
  });

  test('round', () {
    var rect = new Rect(11.4, 26.6, 17.8, 9.2);
    expect(rect.round(), new Rect(11.0, 27.0, 18.0, 9.0));
  });

  test('toInt', () {
    var rect = new Rect(11.4, 26.6, 17.8, 9.2);
    var b = rect.toInt();
    expect(b, new Rect(11, 26, 17, 9));

    expect(b.left is int, isTrue);
    expect(b.top is int, isTrue);
    expect(b.width is int, isTrue);
    expect(b.height is int, isTrue);
  });
}
