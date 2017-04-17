// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library rect_test;

import 'dart:math';
import 'package:unittest/unittest.dart';

main() {
  Rectangle createRectangle(List<num> a) {
    return a != null
        ? new Rectangle(a[0], a[1], a[2] - a[0], a[3] - a[1])
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
      [
        [10, 10, 20, 20],
        [15, 15, 25, 25],
        [15, 15, 20, 20]
      ],
      [
        [10, 10, 20, 20],
        [20, 0, 30, 10],
        [20, 10, 20, 10]
      ],
      [
        [0, 0, 1, 1],
        [10, 11, 12, 13],
        null
      ],
      [
        [11, 12, 98, 99],
        [22, 23, 34, 35],
        [22, 23, 34, 35]
      ]
    ];

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

  test('boundingBox', () {
    var tests = [
      [
        [10, 10, 20, 20],
        [15, 15, 25, 25],
        [10, 10, 25, 25]
      ],
      [
        [10, 10, 20, 20],
        [20, 0, 30, 10],
        [10, 0, 30, 20]
      ],
      [
        [0, 0, 1, 1],
        [10, 11, 12, 13],
        [0, 0, 12, 13]
      ],
      [
        [11, 12, 98, 99],
        [22, 23, 34, 35],
        [11, 12, 98, 99]
      ]
    ];

    for (var test in tests) {
      var r0 = createRectangle(test[0]);
      var r1 = createRectangle(test[1]);
      var expected = createRectangle(test[2]);

      expect(r0.boundingBox(r1), expected);
      expect(r1.boundingBox(r0), expected);
    }
  });

  test('containsRectangle', () {
    var r = new Rectangle(-10, 0, 20, 10);
    expect(r.containsRectangle(r), isTrue);

    expect(
        r.containsRectangle(
            new Rectangle(double.NAN, double.NAN, double.NAN, double.NAN)),
        isFalse);

    var r2 = new Rectangle(0, 2, 5, 5);
    expect(r.containsRectangle(r2), isTrue);
    expect(r2.containsRectangle(r), isFalse);

    r2 = new Rectangle(-11, 2, 5, 5);
    expect(r.containsRectangle(r2), isFalse);
    r2 = new Rectangle(0, 2, 15, 5);
    expect(r.containsRectangle(r2), isFalse);
    r2 = new Rectangle(0, 2, 5, 10);
    expect(r.containsRectangle(r2), isFalse);
    r2 = new Rectangle(0, 0, 5, 10);
    expect(r.containsRectangle(r2), isTrue);
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

  test('hashCode', () {
    var a = new Rectangle(0, 1, 2, 3);
    var b = new Rectangle(0, 1, 2, 3);
    expect(a.hashCode, b.hashCode);

    var c = new Rectangle(1, 0, 2, 3);
    expect(a.hashCode == c.hashCode, isFalse);
  });

  {
    // Edge cases for boundingBox/intersection
    edgeTest(a, l) {
      test('edge case $a/$l', () {
        var r = new Rectangle(a, a, l, l);
        expect(r.boundingBox(r), r);
        expect(r.intersection(r), r);
      });
    }

    var bignum1 = 0x20000000000000 + 0.0;
    var bignum2 = 0x20000000000002 + 0.0;
    var bignum3 = 0x20000000000004 + 0.0;
    edgeTest(1.0, bignum1);
    edgeTest(1.0, bignum2);
    edgeTest(1.0, bignum3);
    edgeTest(bignum1, 1.0);
    edgeTest(bignum2, 1.0);
    edgeTest(bignum3, 1.0);
  }

  test("equality with different widths", () {
    var bignum = 0x80000000000008 + 0.0;
    var r1 = new Rectangle(bignum, bignum, 1.0, 1.0);
    var r2 = new Rectangle(bignum, bignum, 2.0, 2.0);
    expect(r1, r2);
    expect(r1.hashCode, r2.hashCode);
    expect(r1.right, r2.right);
    expect(r1.bottom, r2.bottom);
    expect(r1.width, 1.0);
    expect(r2.width, 2.0);
  });

  test('negative lengths', () {
    // Constructor allows negative lengths, but clamps them to zero.
    expect(new Rectangle(4, 4, -2, -2), new Rectangle(4, 4, 0, 0));
    expect(new MutableRectangle(4, 4, -2, -2), new Rectangle(4, 4, 0, 0));

    // Setters clamp negative lengths to zero.
    var r = new MutableRectangle(0, 0, 1, 1);
    r.width = -1;
    r.height = -1;
    expect(r, new Rectangle(0, 0, 0, 0));

    // Test that doubles are clamped to double zero.
    r = new Rectangle(1.5, 1.5, -2.5, -2.5);
    expect(identical(r.width, 0.0), isTrue);
    expect(identical(r.height, 0.0), isTrue);
  });

  // A NaN-value in any rectangle value means the rectange is considered
  // empty (contains no points, doesn't intersect any other rectangle).
  const NaN = double.NAN;
  var isNaN = predicate((x) => x is double && x.isNaN, "NaN");

  test('NaN left', () {
    var rectangles = [
      const Rectangle(NaN, 1, 2, 3),
      new MutableRectangle(NaN, 1, 2, 3),
      new Rectangle.fromPoints(new Point(NaN, 1), new Point(2, 4)),
      new MutableRectangle.fromPoints(new Point(NaN, 1), new Point(2, 4)),
    ];
    for (var r in rectangles) {
      expect(r.containsPoint(new Point(0, 1)), false);
      expect(r.containsRectangle(new Rectangle(0, 1, 2, 3)), false);
      expect(r.intersects(new Rectangle(0, 1, 2, 3)), false);
      expect(r.left, isNaN);
      expect(r.right, isNaN);
    }
  });

  test('NaN top', () {
    var rectangles = [
      const Rectangle(0, NaN, 2, 3),
      new MutableRectangle(0, NaN, 2, 3),
      new Rectangle.fromPoints(new Point(0, NaN), new Point(2, 4)),
      new MutableRectangle.fromPoints(new Point(0, NaN), new Point(2, 4)),
    ];
    for (var r in rectangles) {
      expect(r.containsPoint(new Point(0, 1)), false);
      expect(r.containsRectangle(new Rectangle(0, 1, 2, 3)), false);
      expect(r.intersects(new Rectangle(0, 1, 2, 3)), false);
      expect(r.top, isNaN);
      expect(r.bottom, isNaN);
    }
  });

  test('NaN width', () {
    var rectangles = [
      const Rectangle(0, 1, NaN, 3),
      new MutableRectangle(0, 1, NaN, 3),
      new Rectangle.fromPoints(new Point(0, 1), new Point(NaN, 4)),
      new MutableRectangle.fromPoints(new Point(0, 1), new Point(NaN, 4)),
    ];
    for (var r in rectangles) {
      expect(r.containsPoint(new Point(0, 1)), false);
      expect(r.containsRectangle(new Rectangle(0, 1, 2, 3)), false);
      expect(r.intersects(new Rectangle(0, 1, 2, 3)), false);
      expect(r.right, isNaN);
      expect(r.width, isNaN);
    }
  });

  test('NaN heigth', () {
    var rectangles = [
      const Rectangle(0, 1, 2, NaN),
      new MutableRectangle(0, 1, 2, NaN),
      new Rectangle.fromPoints(new Point(0, 1), new Point(2, NaN)),
      new MutableRectangle.fromPoints(new Point(0, 1), new Point(2, NaN)),
    ];
    for (var r in rectangles) {
      expect(r.containsPoint(new Point(0, 1)), false);
      expect(r.containsRectangle(new Rectangle(0, 1, 2, 3)), false);
      expect(r.intersects(new Rectangle(0, 1, 2, 3)), false);
      expect(r.bottom, isNaN);
      expect(r.height, isNaN);
    }
  });
}
