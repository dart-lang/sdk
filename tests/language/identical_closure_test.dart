// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var myIdentical = identical;

class Point {
  num x, y;
  Point(this.x, this.y);
}

main() {
  // Smi.
  Expect.isTrue(myIdentical(42, 42));
  Expect.isFalse(myIdentical(42, 41));

  // Double.
  Expect.isTrue(myIdentical(42.0, 42.0));
  Expect.isFalse(myIdentical(42.0, 41.0));

  // Mint (2^45).
  Expect.isTrue(myIdentical(35184372088832,35184372088832));
  Expect.isFalse(myIdentical(35184372088832,35184372088831));

  // Bigint (2^76).
  Expect.isTrue(myIdentical(75557863725914323419136,
                            75557863725914323419136));
  Expect.isFalse(myIdentical(75557863725914323419136,
                             75557863725914323419137));

  // Different types.
  Expect.isFalse(myIdentical(42, 42.0));
  Expect.isFalse(myIdentical("hello", 41));

  // Points.
  var p = new Point(1,1);
  var q = new Point(1,1);
  Expect.isFalse(myIdentical(p, q));

  // Strings.
  var a = "hello";
  var b = "hello";
  // Identical strings are coalesced into single instances.
  Expect.isTrue(myIdentical(a, b));

  // Null and NaN handling.
  Expect.isFalse(myIdentical(42, null));
  Expect.isTrue(myIdentical(null, null));
  Expect.isTrue(myIdentical(double.NAN, double.NAN));
}