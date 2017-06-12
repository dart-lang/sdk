// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to verify that factory classes are working.

import "package:expect/expect.dart";

abstract class Point {
  factory Point(int x, int y) = PointImplementation;

  final int x;
  final int y;
}

class PointImplementation implements Point {
  const PointImplementation(int x, int y)
      : this.x = x,
        this.y = y;
  final int x;
  final int y;
}

class DefaultImplementationTest {
  static void testMain() {
    Point point = new Point(4, 2);
    Expect.equals(4, point.x);
    Expect.equals(2, point.y);
  }
}

main() {
  DefaultImplementationTest.testMain();
}
