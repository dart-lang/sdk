// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show pi;
import 'common/test_helper.dart';

abstract class Shape {}

class Square implements Shape {
  final double length;
  Square(this.length);
}

class Circle implements Shape {
  final double radius;
  Circle(this.radius);
}

double calculateArea(Shape shape) => // LINE_A
    switch (shape) {
      Square(length: final l) when l >= 0 => l * l,
      Circle(radius: final r) when r >= 0 => pi * r * r,
      Square(length: final l) when l < 0 => -1,
      Circle(radius: final r) when r < 0 => -1,
      Shape() => 0
    };

void testMain() {
  calculateArea(Circle(-123));
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
