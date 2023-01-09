// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Syntax errors such as using `base` keyword in a place other than a class or
// mixin.

abstract class BaseMembers {
  base int foo;
// ^
// [analyzer] unspecified
// [cfe] unspecified

  int bar(base int x);
// ^
// [analyzer] unspecified
// [cfe] unspecified

  base void bar2();
// ^
// [analyzer] unspecified
// [cfe] unspecified
}

base base class BaseDuplicateClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

base abstract class BaseAbstractClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class BaseVariable {
  int foo() {
    base var x = 2;
// ^
// [analyzer] unspecified
// [cfe] unspecified
    return x;
  }
}