// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  const f0 = 42;
  const f1; //# 01: compile-time error
  const int f2 = 87;
  const int f3; //# 02: compile-time error
  Expect.equals(42, f0);
  Expect.equals(87, f2);

  Expect.equals(42, F0);
  Expect.equals(null, F1); //# 03: continued
  Expect.equals(87, F2);
  Expect.equals(null, F3); //# 04: continued

  Expect.isTrue(P0 is Point);
  Expect.isTrue(P1 is int); //  //# 05: compile-time error
  Expect.isTrue(P2 is Point); //# 06: compile-time error
  Expect.isTrue(P3 is int); //  //# 07: compile-time error

  Expect.isTrue(A0 is int);
  Expect.isTrue(A1 is int);
  Expect.isTrue(A2 is int); //# 08: compile-time error
  Expect.isTrue(A3 is int); //# 08: continued

  Expect.isTrue(C0.X is C1);
  Expect.isTrue(C0.X.x is C1); //# 09: compile-time error

  Expect.equals("Hello 42", B2);
  Expect.equals("42Hello", B3); //# 10: compile-time error

  const cf1 = identical(const Point(1, 2), const Point(1, 2));

  const cf2 = identical(const Point(1, 2), new Point(1, 2)); // //# 11: compile-time error

  var f4 = B4; //  //# 12: compile-time error
  var f5 = B5;
}

const F0 = 42;
const F1; //                //# 03: syntax error
const int F2 = 87;
const int F3; //            //# 04: syntax error

class Point {
  final x, y;
  const Point(this.x, this.y);
  operator +(int other) => x;
}

// Check that compile time expressions can include invocations of
// user-defined const constructors.
const P0 = const Point(0, 0);
const P1 = const Point(0, 0) + 1; //# 05: continued
const P2 = new Point(0, 0); //      //# 06: continued
const P3 = new Point(0, 0) + 1; //  //# 07: continued

// Check that we cannot have cyclic references in compile time
// expressions.
const A0 = 42;
const A1 = A0 + 1;
const A2 = A3 + 1; //# 08: continued
const A3 = A2 + 1; //# 08: continued

class C0 {
  static const X = const C1();
}

class C1 {
  const C1()
      : x = C0.X //# 09: continued
  ;
  final x = null;
}

// Check that sub-expressions of binary + are numeric.
const B0 = 42;
const B1 = "Hello";
const B2 = "$B1 $B0";
const B3 = B0 + B1; //# 10: continued

// Check identical.

const B4 = identical(1, new Point(1,2)); // //# 12: compile-time error
const B5 = identical(1, const Point(1, 2));
