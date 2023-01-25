// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

class Circle {
  final double radius;

  Circle(this.radius);
}

test1(dynamic x) =>
  switch (x) {
    Circle(radius: var r) when r > 0 => r * r * math.pi,
    _ => null
  };

dynamic Function(dynamic)? captured;

test2(dynamic x) =>
  switch (x) {
    [int a, int b] when (captured = (x) { return a + b; }) is dynamic => captured!(a = b),
    [String a, String b] when (captured = (x) { return a + b; }) is dynamic => captured!(a = b),
    _ => null
  };

test3(dynamic x) {
  switch (x) {
    case [int a, int b] when (captured = (x) { return a + b; }) is dynamic:
      return captured!(a = b);
    case [String a, String b] when (captured = (x) { return a + b; }) is dynamic:
      return captured!(a = b);
    default:
      return null;
  }
}

main() {
  expectEquals(math.pi, test1(new Circle(1)));
  expectEquals(null, test1(null));

  expectEquals(4, test2([1, 2]));
  expectEquals("twotwo", test2(["one", "two"]));
  expectEquals(null, test2(null));

  expectEquals(4, test3([1, 2]));
  expectEquals("twotwo", test3(["one", "two"]));
  expectEquals(null, test3(null));

  print('success');
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
