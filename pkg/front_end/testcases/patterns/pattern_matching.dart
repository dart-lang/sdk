// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

sealed class Shape {
  double calculateArea();
}

class Square implements Shape {
  final double length;
  Square(this.length);
  double calculateArea() => length * length;
}

class Circle implements Shape {
  final double radius;
  Circle(this.radius);
  double calculateArea() => math.pi * radius * radius;
}

double calculateArea(Shape shape) => switch (shape) {
  Square(length: var l) => l * l,
  Circle(radius: var r) => math.pi * r * r
};

main() {
  var s1 = Square(2);
  expect(s1.calculateArea(), calculateArea(s1));

  var s2 = Circle(3);
  expect(s2.calculateArea(), calculateArea(s2));
}

expect(expected, actual) {
  if (expected != actual) throw "Expected $expected, actual $actual";
}