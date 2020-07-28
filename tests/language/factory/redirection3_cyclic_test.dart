// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a cycle in redirecting factories leads to a compile-time error.

class A {
  factory A.foo() = B;
  //      ^
  // [cfe] Cyclic definition of factory 'A.foo'.
}

class B implements A {
  factory B() = C.bar;
}

class C implements B {
  factory C.bar() = C.foo;
  //                ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RECURSIVE_FACTORY_REDIRECT
  factory C.foo() = C.bar();
  //                ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RECURSIVE_FACTORY_REDIRECT
  //                  ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                     ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Expected an identifier, but got '('.
  //                     ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
  C();
}

main() {
  new A.foo();
}
