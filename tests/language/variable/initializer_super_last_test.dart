// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable-asserts
//
// Dart test program testing assert statements.

import "package:expect/expect.dart";

class S {
  const S();
  const S.named();
}

class C extends S {
  final int x;
  C.cc01(int x) : x = x, super();
  C.cc02(int x) : x = x, super.named();
  C.cc03(this.x) : super();
  C.cc04(this.x) : super.named();
  C.cc05(int x) : x = x, assert(x == x), super();
  C.cc06(int x) : x = x, assert(x == x), super.named();
  C.cc07(this.x) : assert(x == x), super();
  C.cc08(this.x) : assert(x == x), super.named();
  C.cc09(int x)
    : super(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      x = x;
  //    ^
  // [cfe] Can't have initializers after 'super'.
  C.cc10(int x)
    : super.named(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      x = x;
  //    ^
  // [cfe] Can't have initializers after 'super'.
  C.cc11(this.x)
    : super(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.
  C.cc12(this.x)
    : super.named(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.
  C.cc13(int x)
    : super(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      x = x,
      //^
      // [cfe] Can't have initializers after 'super'.
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.
  C.cc14(int x)
    : super.named(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      x = x,
      //^
      // [cfe] Can't have initializers after 'super'.
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.
  C.cc15(int x)
    : x = x,
      super(),
      // [error column 7, length 5]
      // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.
  C.cc16(int x)
    : x = x,
      super.named(),
      // [error column 7, length 5]
      // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.

  const C.cc17(int x) : x = x, super();
  const C.cc18(int x) : x = x, super.named();
  const C.cc19(this.x) : super();
  const C.cc20(this.x) : super.named();
  const C.cc21(int x) : x = x, assert(x == x), super();
  const C.cc22(int x) : x = x, assert(x == x), super.named();
  const C.cc23(this.x) : assert(x == x), super();
  const C.cc24(this.x) : assert(x == x), super.named();
  const C.cc25(int x)
    : super(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      x = x;
  //    ^
  // [cfe] Can't have initializers after 'super'.
  const C.cc26(int x)
    : super.named(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      x = x;
  //    ^
  // [cfe] Can't have initializers after 'super'.
  const C.cc27(this.x)
    : super(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.
  const C.cc28(this.x)
    : super.named(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.
  const C.cc29(int x)
    : super(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      x = x,
      //^
      // [cfe] Can't have initializers after 'super'.
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.
  const C.cc30(int x)
    : super.named(),
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      x = x,
      //^
      // [cfe] Can't have initializers after 'super'.
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.
  const C.cc31(int x)
    : x = x,
      super(),
      // [error column 7, length 5]
      // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.
  const C.cc32(int x)
    : x = x,
      super.named(),
      // [error column 7, length 5]
      // [analyzer] COMPILE_TIME_ERROR.SUPER_INVOCATION_NOT_LAST
      assert(x == x);
  //  ^
  // [cfe] Can't have initializers after 'super'.
}

main() {
  // Ensure that erroneous constructors are actually needed.
  new C.cc01(42);
  new C.cc02(42);
  new C.cc03(42);
  new C.cc04(42);
  new C.cc05(42);
  new C.cc06(42);
  new C.cc07(42);
  new C.cc08(42);
  new C.cc09(42);
  new C.cc10(42);
  new C.cc11(42);
  new C.cc12(42);
  new C.cc13(42);
  new C.cc14(42);
  new C.cc15(42);
  new C.cc16(42);

  const C.cc17(42);
  const C.cc18(42);
  const C.cc19(42);
  const C.cc20(42);
  const C.cc21(42);
  const C.cc22(42);
  const C.cc23(42);
  const C.cc24(42);
  const C.cc25(42);
  const C.cc26(42);
  const C.cc27(42);
  const C.cc28(42);
  const C.cc29(42);
  const C.cc30(42);
  const C.cc31(42);
  const C.cc32(42);
}
