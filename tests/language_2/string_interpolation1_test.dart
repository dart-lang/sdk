// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A dollar must be followed by a "{" or an identifier.

class A {
  final String str;
  const A(this.str);
}

class StringInterpolation1NegativeTest {
  // Dollar not followed by "{" or identifier.
  static const DOLLAR = const A("$");
  // [error line 14, column 35, length 0]
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  // [error line 14, column 35, length 0]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  //                              ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  static testMain() {
    print(DOLLAR);
  }
}

main() {
  StringInterpolation1NegativeTest.testMain();
}
