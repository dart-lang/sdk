// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=anonymous-methods

// This test verifies that `super` can't be used inside a parameterless
// anonymous method.
//
// Note that whereas the analyzer has just a single representation of `super`,
// the CFE has a large number of them. So this test tries to exercise each CFE
// representation.

class Base {
  int i = 0;
  operator[](int index) => null;
  operator[]=(int index, Object? value) {}
  void m() {}
}

class Derived extends Base {
  test() {
    // CFE AST node: IfNullSuperIndexSet
    this.=> super[0] ??= 1;
//          ^^^^^
// [analyzer] unspecified
// [cfe] unspecified

    // CFE AST node: SuperIndexSet
    this.=> super[0] = 1;
//          ^^^^^
// [analyzer] unspecified
// [cfe] unspecified

    // CFE AST node: SuperIncDec
    this.=> super.i++;
//          ^^^^^
// [analyzer] unspecified
// [cfe] unspecified
    this.=> ++super.i;
//            ^^^^^
// [analyzer] unspecified
// [cfe] unspecified

    // CFE AST node: SuperMethodInvocation
    this.=> super.m();
//          ^^^^^
// [analyzer] unspecified
// [cfe] unspecified

    // CFE AST node: CompoundSuperIndexSet
    this.=> super[0] += 1;
//          ^^^^^
// [analyzer] unspecified
// [cfe] unspecified

    // CFE AST node: SuperPropertySet
    this.=> super.i = 0;
//          ^^^^^
// [analyzer] unspecified
// [cfe] unspecified

    // CFE AST node: SuperPropertyGet
    this.=> super.i;
//          ^^^^^
// [analyzer] unspecified
// [cfe] unspecified
  }
}

mixin Mixin on Base {
  test() {
    // CFE AST node: AbstractSuperPropertyGet
    this.=> super.i;
//          ^^^^^
// [analyzer] unspecified
// [cfe] unspecified

    // CFE AST node: AbstractSuperMethodInvocation
    this.=> super.m();
//          ^^^^^
// [analyzer] unspecified
// [cfe] unspecified

    // CFE AST node: AbstractSuperPropertySet
    this.=> super.i = 0;
//          ^^^^^
// [analyzer] unspecified
// [cfe] unspecified
  }
}

main() {}
