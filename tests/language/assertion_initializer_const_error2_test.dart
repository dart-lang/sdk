// Copyright (c) 201, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--assert_initializer
//
// Dart test program testing assert statements.

import "package:expect/expect.dart";

class C {
  final int x;
  // Const constructors.
  const C.cc01(this.x, y)
      : assert(x < y)  //# cc01: checked mode compile-time error
      ;
  const C.cc02(x, y) : x = x
      , assert(x < y)  //# cc02: checked mode compile-time error
      ;
  const C.cc03(x, y) :
      assert(x < y),  //# cc03: checked mode compile-time error
      x = x;
  const C.cc04(this.x, y) : super()
      , assert(x < y)  //# cc04: checked mode compile-time error
      ;
  const C.cc05(this.x, y) :
      assert(x < y),   //# cc05: checked mode compile-time error
      super();
  const C.cc06(x, y) : x = x, super()
      , assert(x < y)  //# cc06: checked mode compile-time error
      ;
  const C.cc07(x, y) :
      assert(x < y),  //# cc07: checked mode compile-time error
      super(), x = x;
  const C.cc08(x, y) :
      assert(x < y),  //# cc08: checked mode compile-time error
      super(), x = x
      , assert(y > x)  //# cc08: continued
      ;
  const C.cc09(this.x, y)
      : assert(x < y, "$x < $y")  //# cc09: checked mode compile-time error
      ;
  const C.cc10(this.x, y)
      : assert(x < y,)  //# cc10: checked mode compile-time error
      ;
  const C.cc11(this.x, y)
      : assert(x < y, "$x < $y",)  //# cc11: checked mode compile-time error
      ;
}


main() {
  const C.cc01(2, 1);  //# cc01: continued
  const C.cc02(2, 1);  //# cc02: continued
  const C.cc03(2, 1);  //# cc03: continued
  const C.cc04(2, 1);  //# cc04: continued
  const C.cc05(2, 1);  //# cc05: continued
  const C.cc06(2, 1);  //# cc06: continued
  const C.cc07(2, 1);  //# cc07: continued
  const C.cc08(2, 1);  //# cc08: continued
  const C.cc09(2, 1);  //# cc09: continued
  const C.cc10(2, 1);  //# cc10: continued
  const C.cc11(2, 1);  //# cc11: continued
}
