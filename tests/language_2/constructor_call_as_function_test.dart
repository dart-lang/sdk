// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to make sure we catch missing new or const
// when allocating a new object.

class Point {
  const Point(this.x, this.y);
  final int x;
  final int y;
}

main() {
  Point p = Point(1, 2); //# 01: compile-time error, static type warning, runtime error
}
