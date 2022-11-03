// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Syntax errors such as using `sealed` keyword in a place other than a class or
// mixin.

abstract class SealedMembers {
  sealed int foo;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  int bar(sealed int x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  sealed void bar2();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

sealed abstract class SealedAndAbstractClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified


abstract sealed class SealedAndAbstractClass2 {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class SealedVariable {
  int foo() {
    sealed var x = 2;
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    return x;
  }
}