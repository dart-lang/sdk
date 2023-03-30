// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show pi;

abstract class Shape {}

class Square implements Shape {
  final double length;
  Square(this.length);
}

class Circle implements Shape {
  final double radius;
  Circle(this.radius);
}

double calculateArea(Shape shape) => switch (shape) {
      Square(length: var l) when l >= 0 => l * l,
      Circle(radius: var r) when r >= 0 => pi * r * r,
      Square(length: var l) when l < 0 => -1,
      Circle(radius: var r) when r < 0 => -1,
      Shape() => 0
    };

testMain() {
  calculateArea(Circle(-123));
}
