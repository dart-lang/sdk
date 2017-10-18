// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  final f0 = 42;
  final f1; //# 01: compile-time error
  final int f2 = 87;
  final int f3; //# 02: compile-time error
  Expect.equals(42, f0);
  Expect.equals(87, f2);

  Expect.equals(42, F0);
  Expect.equals(null, F1); //# 03: continued
  Expect.equals(87, F2);
  Expect.equals(null, F3); //# 04: continued

  Expect.isTrue(P0 is Point);
  Expect.isTrue(P1 is int);
  Expect.isTrue(P2 is Point);
  Expect.isTrue(P3 is int);

  Expect.isTrue(A0 is int);
  Expect.isTrue(A1 is int);
  Expect.isTrue(A2 is int); //# 08: runtime error
  Expect.isTrue(A3 is int); //# 08: continued

  Expect.isTrue(C0.X is C1);
  Expect.isTrue(C0.X.x is C1); //# 09: compile-time error

  Expect.equals("Hello 42", B2);
  Expect.equals("42Hello", B3); //# 10: compile-time error
}

final F0 = 42;
final F1; //                //# 03: compile-time error
final int F2 = 87;
final int F3; //            //# 04: compile-time error

class Point {
  final x, y;
  const Point(this.x, this.y);
  operator +(int other) => x;
}

// Check that compile time expressions can include invocations of
// user-defined final constructors.
final P0 = const Point(0, 0);
final P1 = const Point(0, 0) + 1;
final P2 = new Point(0, 0);
final P3 = new Point(0, 0) + 1;

// Check that we cannot have cyclic references in compile time
// expressions.
final A0 = 42;
final A1 = A0 + 1;
final A2 = A3 + 1; //# 08: continued
final A3 = A2 + 1; //# 08: continued

class C0 {
  static final X = const C1();
}

class C1 {
  const C1()
      : x = C0.X //# 09: continued
  ;
  final x = null;
}

// Check that sub-expressions of binary + are numeric.
final B0 = 42;
final B1 = "Hello";
final B2 = "$B1 $B0";
final B3 = B0 + B1; //# 10: continued
