// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  const f0 = 42;

  const int f2 = 87;

  Expect.equals(42, f0);
  Expect.equals(87, f2);

  Expect.equals(42, F0);

  Expect.equals(87, F2);


  Expect.isTrue(P0 is Point);




  Expect.isTrue(A0 is int);
  Expect.isTrue(A1 is int);



  Expect.isTrue(C0.X is C1);


  Expect.equals("Hello 42", B2);


  const cf1 = identical(const Point(1, 2), const Point(1, 2));




  var f5 = B5;
}

const F0 = 42;

const int F2 = 87;


class Point {
  final x, y;
  const Point(this.x, this.y);
  operator +(int other) => x;
}

// Check that compile time expressions can include invocations of
// user-defined const constructors.
const P0 = const Point(0, 0);




// Check that we cannot have cyclic references in compile time
// expressions.
const A0 = 42;
const A1 = A0 + 1;



class C0 {
  static const X = const C1();
}

class C1 {
  const C1()

  ;
  final x = null;
}

// Check that sub-expressions of binary + are numeric.
const B0 = 42;
const B1 = "Hello";
const B2 = "$B1 $B0";


// Check identical.


const B5 = identical(1, const Point(1, 2));
