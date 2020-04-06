// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart spec 0.03, section 11.10 - generative constructors can only have return
// statements in the form 'return;'.
class A {
  int x;
  A(this.x) {
    return;
  }
  A.test1(this.x) {
    return this;
//  ^
// [cfe] Constructors can't have a return type.
//         ^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATIVE_CONSTRUCTOR
  }
  A.test2(this.x) {
    return null;
//  ^
// [cfe] Constructors can't have a return type.
//         ^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATIVE_CONSTRUCTOR
  }
  int foo(int y) => x + y;
}

class B {
  B() => B._();
  //  ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATIVE_CONSTRUCTOR
  //     ^
  // [cfe] Constructors can't have a return type.

  B._();
}

class C {
  int value;
  C() : value = 1 { return null; }
  //                ^
  // [cfe] Constructors can't have a return type.
  //                       ^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATIVE_CONSTRUCTOR
}

class D {
  int value = -1;
  D(): value = 1 => D._();
  //             ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATIVE_CONSTRUCTOR
  //                ^
  // [cfe] Constructors can't have a return type.

  D._();
}

main() {
  Expect.equals((new A(1)).foo(10), 11);
  Expect.equals((new A.test1(1)).foo(10), 11);
  Expect.equals((new A.test2(1)).foo(10), 11);
  new B();
  new C();
  new D();
}
