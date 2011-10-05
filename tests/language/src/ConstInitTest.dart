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

    // class order doesn't matter.
    Expect.equals(1, C2.N);
    Expect.equals(4, C2.O);
    Expect.equals(6, C2.P);
    Expect.equals(0, C2.Q.x_);
    Expect.equals(0, C2.Q.y_);

    // Nor the order of top level constants
    Expect.equals(1, X.x_);
    Expect.equals(4, X.y_);
  }
}

class C2 {
  static final Q = const Point(0, 0);
  static final P = 2 * (O - N);
  static final O = 1 + 3;
  static final N = 1;
}

// Top level final
final X = const Point(C2.N, C2.O);

main() {
  ConstInitTest.testMain();
}
