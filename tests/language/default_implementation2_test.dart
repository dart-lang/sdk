// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to verify incompatible constructor types

abstract class Point {
  factory Point(x, y) = PointImplementation;
}

class PointImplementation implements Point {
   PointImplementation(int x, int y) {} //# static type warning
}

main() {
  new Point(1, 2);
}
