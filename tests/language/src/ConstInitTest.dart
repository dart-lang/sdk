// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that initializers of static final fields are compile time constants.

class Point {
  final x_;
  final y_;
  const Point(x, y) : x_ = x, y_ = y;
}

class ConstInitTest {
  static final N = 1;
  static final O = 1 + 3;
  static final P = 2 * (O - N);
  static final Q = const Point(0, 0);

  static final Q2 = const Point(0, 0);
  static final P2 = 2 * (O - N);
  static final O2 = 1 + 3;
  static final N2 = 1;

  static testMain() {
    Expect.equals(1, N);
    Expect.equals(4, O);
    Expect.equals(6, P);
    Expect.equals(0, Q.x_);
    Expect.equals(0, Q.y_);
  }
}

main() {
  ConstInitTest.testMain();
}
