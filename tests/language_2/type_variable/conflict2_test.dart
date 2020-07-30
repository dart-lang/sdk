// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 13134. Invocation of a type parameter.

import "package:expect/expect.dart";

class C<T> {
  noSuchMethod(Invocation im) {
    throw "noSuchMethod shouldn't be called in this test.";
  }

  // This is equivalent to (T).call(). See issue 19725
  foo() => T();
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Method not found: 'T'.

  // T is in scope, even in static context. Compile-time error to call this.T().
  static bar() => T();
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Method not found: 'T'.
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC

  // X is not in scope. NoSuchMethodError.
  static baz() => X();
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] Method not found: 'X'.

  // Class 'C' has no static method 'T': NoSuchMethodError.
  static qux() => C.T();
  //                ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] Method not found: 'C.T'.

  // Class '_Type' has no instance method 'call': NoSuchMethodError.
  quux() => (T)();
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
  //           ^
  // [cfe] The method 'call' isn't defined for the class 'Type'.

  // Runtime type T not accessible from static context. Compile-time error.
  static corge() => (T)();
  //                ^^^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
  //                 ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC
  // [cfe] Type variables can't be used in static members.
  //                   ^
  // [cfe] The method 'call' isn't defined for the class 'Type'.

  // Class '_Type' has no [] operator: NoSuchMethodError.
  grault() => T[0];
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]' isn't defined for the class 'Type'.

  // Runtime type T not accessible from static context. Compile-time error.
  static garply() => T[0];
  //                 ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC
  // [cfe] Type variables can't be used in static members.
  //                  ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]' isn't defined for the class 'Type'.

  // Class '_Type' has no member m: NoSuchMethodError.
  waldo() => T.m;
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'm' isn't defined for the class 'Type'.

  // Runtime type T not accessible from static context. Compile-time error.
  static fred() => T.m;
  //               ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC
  // [cfe] Type variables can't be used in static members.
  //                 ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'm' isn't defined for the class 'Type'.
}

main() {
  Expect.throwsNoSuchMethodError(() => new C().foo());
  C.bar();
  Expect.throwsNoSuchMethodError(() => C.baz());
  Expect.throwsNoSuchMethodError(() => C.qux());
  Expect.throwsNoSuchMethodError(() => new C().quux());
  C.corge();
  Expect.throwsNoSuchMethodError(() => new C().grault());
  C.garply();
  Expect.throwsNoSuchMethodError(() => new C().waldo());
  C.fred();
}
