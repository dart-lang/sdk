// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var myIdentical = identical;

class Point {
  num x, y;
  Point(this.x, this.y);
}

main() {
  // Bigint (2^76).
  Expect.isTrue(myIdentical(75557863725914323419136,
                            75557863725914323419136));
  Expect.isFalse(myIdentical(75557863725914323419136,
                             75557863725914323419137));

  // Different types.
  Expect.isFalse(myIdentical(42, 42.0));

  // NaN handling.
  Expect.isTrue(myIdentical(double.NAN, double.NAN));
}
