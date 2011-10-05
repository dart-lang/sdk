// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that initializer is expected after final variable declaration.

class Point {
  final x_;
  final y_;
  const Point(x, y) : x_ = x, y_ = y;
  operator +(int x) { return x; }
}

class ConstInit2NegativeTest {
  static final N = 1;                    // ok
  static final O = 1 + 3;                // ok
  static final P = const Point(0, 0);    // ok
  static final Q = new Point(0, 0) + 1;  // Error: not a compile time const.

  static testMain() {
    Expect.equals(1, N);
    Expect.equals(4, O);
    Expect.equals(0, P.x_);
    Expect.equals(0, Q.x_);
  }
}

main() {
  ConstInit2NegativeTest.testMain();
}
