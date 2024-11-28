// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Base {
  void foo() {}
}

mixin M1 {
  void foo({x}) {}
}

class BaseWithM1 = Base with M1;

mixin M2 {
  void foo() {}
}

class Derived extends BaseWithM1 with M2 {}
//    ^^^^^^^
// [cfe] Applying the mixin 'M2' to 'BaseWithM1' introduces an erroneous override of 'foo'.
//                                    ^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

main() {
  new Derived().foo();
}
