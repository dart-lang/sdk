// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A basic declaring body constructor.

// SharedOptions=--enable-experiment=declaring-constructors

import 'package:expect/expect.dart';

class Point {
  this(var int x, var int y);
}

class PointFinal {
  this(final int x, final int y);
}

void main() {
  var p1 = Point(1, 2);
  Expect.equals(1, p1.x);
  Expect.equals(2, p1.y);

  p1.x = 3;
  Expect.equals(3, p1.x);

  var p2 = PointFinal(3, 4);
  Expect.equals(3, p2.x);
  Expect.equals(4, p2.y);
}
