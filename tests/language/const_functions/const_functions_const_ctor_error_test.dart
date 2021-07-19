// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous const constructors with a body which are enabled with const
// functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const printString = "print";

const var1 = Simple(printString);
//           ^
// [cfe] Constant evaluation error:
class Simple {
  final String name;

  const Simple(this.name) {
//                        ^
// [analyzer] SYNTACTIC_ERROR.CONST_CONSTRUCTOR_WITH_BODY
    assert(this.name != printString);
  }
}

const var2 = Simple2(printString);
class Simple2 {
  final String name;

  const Simple2(this.name) {
//                         ^
// [analyzer] SYNTACTIC_ERROR.CONST_CONSTRUCTOR_WITH_BODY
    return Simple2(this.name);
//  ^
// [cfe] Constructors can't have a return type.
//         ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATIVE_CONSTRUCTOR
  }
}

const var3 = B();
//           ^
// [cfe] Constant evaluation error:
class A {
  const A() {
  //        ^
  // [analyzer] SYNTACTIC_ERROR.CONST_CONSTRUCTOR_WITH_BODY
    assert(1 == 2);
  }
}

class B extends A {
  const B() : super();
}

const var4 = C();
//           ^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
//           ^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
//           ^^^^^
// [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
class C {
  int? x;
}
