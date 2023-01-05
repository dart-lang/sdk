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

main() {
  expectEquals(math.pi, test1(new Circle(1)));
  expectEquals(null, test1(null));

  expectEquals(4, test2([1, 2]));
  expectEquals("twotwo", test2(["one", "two"]));
  expectEquals(null, test2(null));
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
