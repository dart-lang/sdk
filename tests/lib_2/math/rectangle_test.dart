// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'package:expect/expect.dart';

main() {
  testConstruction();
  testIntersection();
  testIntersects();
  testBoundingBox();
  testContainsRectangle();
  testContainsPoint();
  testHashCode();
  testEdgeCases();
  testEquality();
  testNegativeLengths();
  testNaNLeft();
  testNaNTop();
  testNaNWidth();
  testNaNHeight();
}

Rectangle createRectangle(List<num> a) {
  return a != null ? new Rectangle(a[0], a[1], a[2] - a[0], a[3] - a[1]) : null;
}

testConstruction() {
  var r0 = new Rectangle(10, 20, 30, 40);
  Expect.equals('Rectangle (10, 20) 30 x 40', r0.toString());
  Expect.equals(40, r0.right);
  Expect.equals(60, r0.bottom);

  var r1 = new Rectangle.fromPoints(r0.topLeft, r0.bottomRight);
  Expect.equals(r0, r1);

  var r2 = new Rectangle.fromPoints(r0.bottomRight, r0.topLeft);
  Expect.equals(r0, r2);
}

testIntersection() {
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

    Expect.equals(expected, r0.intersection(r1));
    Expect.equals(expected, r1.intersection(r0));
  }
}

testIntersects() {
  var r0 = new Rectangle(10, 10, 20, 20);
  var r1 = new Rectangle(15, 15, 25, 25);
  var r2 = new Rectangle(0, 0, 1, 1);

  Expect.isTrue(r0.intersects(r1));
  Expect.isTrue(r1.intersects(r0));

  Expect.isFalse(r0.intersects(r2));
  Expect.isFalse(r2.intersects(r0));
}

testBoundingBox() {
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

    Expect.equals(expected, r0.boundingBox(r1));
    Expect.equals(expected, r1.boundingBox(r0));
  }
}

testContainsRectangle() {
  var r = new Rectangle(-10, 0, 20, 10);
  Expect.isTrue(r.containsRectangle(r));

  Expect.isFalse(r.containsRectangle(
      new Rectangle(double.NAN, double.NAN, double.NAN, double.NAN)));

  var r2 = new Rectangle(0, 2, 5, 5);
  Expect.isTrue(r.containsRectangle(r2));
  Expect.isFalse(r2.containsRectangle(r));

  r2 = new Rectangle(-11, 2, 5, 5);
  Expect.isFalse(r.containsRectangle(r2));
  r2 = new Rectangle(0, 2, 15, 5);
  Expect.isFalse(r.containsRectangle(r2));
  r2 = new Rectangle(0, 2, 5, 10);
  Expect.isFalse(r.containsRectangle(r2));
  r2 = new Rectangle(0, 0, 5, 10);
  Expect.isTrue(r.containsRectangle(r2));
}

testContainsPoint() {
  var r = new Rectangle(20, 40, 60, 80);

  // Test middle.
  Expect.isTrue(r.containsPoint(new Point(50, 80)));

  // Test edges.
  Expect.isTrue(r.containsPoint(new Point(20, 40)));
  Expect.isTrue(r.containsPoint(new Point(50, 40)));
  Expect.isTrue(r.containsPoint(new Point(80, 40)));
  Expect.isTrue(r.containsPoint(new Point(80, 80)));
  Expect.isTrue(r.containsPoint(new Point(80, 120)));
  Expect.isTrue(r.containsPoint(new Point(50, 120)));
  Expect.isTrue(r.containsPoint(new Point(20, 120)));
  Expect.isTrue(r.containsPoint(new Point(20, 80)));

  // Test outside.
  Expect.isFalse(r.containsPoint(new Point(0, 0)));
  Expect.isFalse(r.containsPoint(new Point(50, 0)));
  Expect.isFalse(r.containsPoint(new Point(100, 0)));
  Expect.isFalse(r.containsPoint(new Point(100, 80)));
  Expect.isFalse(r.containsPoint(new Point(100, 160)));
  Expect.isFalse(r.containsPoint(new Point(50, 160)));
  Expect.isFalse(r.containsPoint(new Point(0, 160)));
  Expect.isFalse(r.containsPoint(new Point(0, 80)));
}

testHashCode() {
  var a = new Rectangle(0, 1, 2, 3);
  var b = new Rectangle(0, 1, 2, 3);
  Expect.equals(b.hashCode, a.hashCode);

  var c = new Rectangle(1, 0, 2, 3);
  Expect.isFalse(a.hashCode == c.hashCode);
}

testEdgeCases() {
  edgeTest(double a, double l) {
    var r = new Rectangle(a, a, l, l);
    Expect.equals(r, r.boundingBox(r));
    Expect.equals(r, r.intersection(r));
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

testEquality() {
  var bignum = 0x80000000000008 + 0.0;
  var r1 = new Rectangle(bignum, bignum, 1.0, 1.0);
  var r2 = new Rectangle(bignum, bignum, 2.0, 2.0);
  Expect.equals(r2, r1);
  Expect.equals(r2.hashCode, r1.hashCode);
  Expect.equals(r2.right, r1.right);
  Expect.equals(r2.bottom, r1.bottom);
  Expect.equals(1.0, r1.width);
  Expect.equals(2.0, r2.width);
}

testNegativeLengths() {
  // Constructor allows negative lengths, but clamps them to zero.
  Expect.equals(new Rectangle(4, 4, 0, 0), new Rectangle(4, 4, -2, -2));
  Expect.equals(new Rectangle(4, 4, 0, 0), new MutableRectangle(4, 4, -2, -2));

  // Setters clamp negative lengths to zero.
  var mutable = new MutableRectangle(0, 0, 1, 1);
  mutable.width = -1;
  mutable.height = -1;
  Expect.equals(new Rectangle(0, 0, 0, 0), mutable);

  // Test that doubles are clamped to double zero.
  var rectangle = new Rectangle(1.5, 1.5, -2.5, -2.5);
  Expect.isTrue(identical(rectangle.width, 0.0));
  Expect.isTrue(identical(rectangle.height, 0.0));
}

testNaNLeft() {
  var rectangles = [
    const Rectangle(double.NAN, 1, 2, 3),
    new MutableRectangle(double.NAN, 1, 2, 3),
    new Rectangle.fromPoints(new Point(double.NAN, 1), new Point(2, 4)),
    new MutableRectangle.fromPoints(new Point(double.NAN, 1), new Point(2, 4)),
  ];
  for (var r in rectangles) {
    Expect.isFalse(r.containsPoint(new Point(0, 1)));
    Expect.isFalse(r.containsRectangle(new Rectangle(0, 1, 2, 3)));
    Expect.isFalse(r.intersects(new Rectangle(0, 1, 2, 3)));
    Expect.isTrue(r.left.isNaN);
    Expect.isTrue(r.right.isNaN);
  }
}

testNaNTop() {
  var rectangles = [
    const Rectangle(0, double.NAN, 2, 3),
    new MutableRectangle(0, double.NAN, 2, 3),
    new Rectangle.fromPoints(new Point(0, double.NAN), new Point(2, 4)),
    new MutableRectangle.fromPoints(new Point(0, double.NAN), new Point(2, 4)),
  ];
  for (var r in rectangles) {
    Expect.isFalse(r.containsPoint(new Point(0, 1)));
    Expect.isFalse(r.containsRectangle(new Rectangle(0, 1, 2, 3)));
    Expect.isFalse(r.intersects(new Rectangle(0, 1, 2, 3)));
    Expect.isTrue(r.top.isNaN);
    Expect.isTrue(r.bottom.isNaN);
  }
}

testNaNWidth() {
  var rectangles = [
    const Rectangle(0, 1, double.NAN, 3),
    new MutableRectangle(0, 1, double.NAN, 3),
    new Rectangle.fromPoints(new Point(0, 1), new Point(double.NAN, 4)),
    new MutableRectangle.fromPoints(new Point(0, 1), new Point(double.NAN, 4)),
  ];
  for (var r in rectangles) {
    Expect.isFalse(r.containsPoint(new Point(0, 1)));
    Expect.isFalse(r.containsRectangle(new Rectangle(0, 1, 2, 3)));
    Expect.isFalse(r.intersects(new Rectangle(0, 1, 2, 3)));
    Expect.isTrue(r.right.isNaN);
    Expect.isTrue(r.width.isNaN);
  }
}

testNaNHeight() {
  var rectangles = [
    const Rectangle(0, 1, 2, double.NAN),
    new MutableRectangle(0, 1, 2, double.NAN),
    new Rectangle.fromPoints(new Point(0, 1), new Point(2, double.NAN)),
    new MutableRectangle.fromPoints(new Point(0, 1), new Point(2, double.NAN)),
  ];
  for (var r in rectangles) {
    Expect.isFalse(r.containsPoint(new Point(0, 1)));
    Expect.isFalse(r.containsRectangle(new Rectangle(0, 1, 2, 3)));
    Expect.isFalse(r.intersects(new Rectangle(0, 1, 2, 3)));
    Expect.isTrue(r.bottom.isNaN);
    Expect.isTrue(r.height.isNaN);
  }
}
