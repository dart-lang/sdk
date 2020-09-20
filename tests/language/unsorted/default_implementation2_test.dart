// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to verify incompatible constructor types

abstract class Point {
  factory Point(int x, int y) = PointImplementation; //# 01: ok
  factory Point(x, y) = PointImplementation; //# 02: compile-time error
}

class PointImplementation implements Point {
   PointImplementation(int x, int y) {}
}

main() {
  new Point(1, 2); //# 01: continued
  new Point(1, 2); //# 02: continued
}
