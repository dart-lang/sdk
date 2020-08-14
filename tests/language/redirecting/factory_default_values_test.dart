// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that parameter default values are disallowed in a redirecting factory.

import "package:expect/expect.dart";

class A {
  A(this.a, [this.b = 0]);
  factory A.f(int a) = A;
  factory A.g(int a, [int b = 0]) = A;
  //                      ^
  // [analyzer] COMPILE_TIME_ERROR.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR
  //                          ^
  // [cfe] Can't have a default value here because any default values of 'A' would be used instead.
  factory A.h(int a, {int b: 0}) = A;
  //                      ^
  // [analyzer] COMPILE_TIME_ERROR.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR
  //                         ^
  // [cfe] Can't have a default value here because any default values of 'A' would be used instead.
  //                               ^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_INVALID_FUNCTION_TYPE
  // [cfe] The constructor function type 'A Function(int, [int])' isn't a subtype of 'A Function(int, {int b})'.

  int a;
  int b;
}

main() {
  var x = new A.f(42);
  Expect.equals(x.a, 42);
  Expect.equals(x.b, 0);

  var y = new A.f(42, 43);
  //             ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  // [cfe] Too many positional arguments: 1 allowed, but 2 found.
}
