// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that compile-time errors in the arguments are reported when the named
// arguments are placed before the positional.

const a42 = const A(42);

class A {
  final int value;

  const A(this.value);
}

class B {
  final A a;

  const B(this.a) : assert(identical(a, a42));
}

foo(B x, {required B y}) {}

test() {
  foo(const B(const A(0)), y: const B(new A(42)));
  //  ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_THROWS_EXCEPTION
  //        ^
  // [cfe] Constant evaluation error:
  //                                  ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
  // [cfe] New expression is not a constant expression.
  //                                      ^
  // [cfe] New expression is not a constant expression.
  foo(y: const B(new A(42)), const B(const A(0)));
  //             ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
  // [cfe] New expression is not a constant expression.
  //                 ^
  // [cfe] New expression is not a constant expression.
  //                         ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_THROWS_EXCEPTION
  //                               ^
  // [cfe] Constant evaluation error:
}

main() {}
