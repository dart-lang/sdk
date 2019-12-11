// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo(a, [b]) {}

bar(a, {b}) {}

class A {
  A();
  A.test(a, [b]);
}

class B {
  B()
    : super.test(b: 1)
    //^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER
    // [cfe] Superclass has no constructor named 'Object.test'.
  ;
}

class C extends A {
  C()
    : super.test(b: 1)
    //          ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
    // [cfe] Too few positional arguments: 1 required, 0 given.
    //           ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_NAMED_PARAMETER
  ;
}

class D {
  D();
  D.test(a, {b});
}

class E extends D {
  E()
    : super.test(b: 1)
    //          ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
    // [cfe] Too few positional arguments: 1 required, 0 given.
  ;
}

main() {
  new A.test(b: 1);
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
  // [cfe] Too few positional arguments: 1 required, 0 given.
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_NAMED_PARAMETER
  new B();
  new C();
  new D.test(b: 1);
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
  // [cfe] Too few positional arguments: 1 required, 0 given.
  new E();
  foo(b: 1);
  // ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
  // [cfe] Too few positional arguments: 1 required, 0 given.
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_NAMED_PARAMETER
  bar(b: 1);
  // ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
  // [cfe] Too few positional arguments: 1 required, 0 given.
}
