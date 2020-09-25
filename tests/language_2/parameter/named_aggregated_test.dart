// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.

class TypeTester<T> {}

// Expect compile-time error as no default values are allowed
// in closure type definitions.
typedef void Callback([String msg = ""]);
//                                ^
// [analyzer] SYNTACTIC_ERROR.DEFAULT_VALUE_IN_FUNCTION_TYPE
// [cfe] Can't have a default value in a function type.

class NamedParametersAggregatedTests {
  static int F31(int a, {int b: 20, int c: 30}) {
    return 100 * (100 * a + b) + c;
  }

  static int f_missing_comma(a [b = 42]) => a;
  //                           ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ')' before this.

  var _handler = null;

  // Expect compile-time error as no default values
  // are allowed in closure type.
  void InstallCallback(void cb({String msg : null})) {
  //                                       ^
  // [analyzer] SYNTACTIC_ERROR.DEFAULT_VALUE_IN_FUNCTION_TYPE
  // [cfe] Can't have a default value in a function type.
    _handler = cb;
  }
}

main() {
  // Expect compile-time error due to missing comma in function definition.
  NamedParametersAggregatedTests.f_missing_comma(10, 25);
  //                                            ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  // [cfe] Too many positional arguments: 1 allowed, but 2 found.

  // Expect compile-time error due to duplicate named argument.
  NamedParametersAggregatedTests.F31(10, b: 25, b:35);
  //                                            ^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_NAMED_ARGUMENT
  // [cfe] Duplicated named argument 'b'.

  // Expect compile-time error due to missing positional argument.
  NamedParametersAggregatedTests.F31(b: 25, c: 35);
  //                                ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
  // [cfe] Too few positional arguments: 1 required, 0 given.

  new TypeTester<Callback>();

  (new NamedParametersAggregatedTests()).InstallCallback(null);
}
