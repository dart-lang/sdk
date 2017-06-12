// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.

import "package:expect/expect.dart";

class TypeTester<T> {}

// Expect compile-time error as no default values are allowed
// in closure type definitions.
typedef void Callback([String msg
 = "" //# 01: compile-time error
    ]);

class NamedParametersAggregatedTests {
  static int F31(int a, {int b: 20, int c: 30}) {
    return 100 * (100 * a + b) + c;
  }

  static int f_missing_comma(a
    [b = 42] //# 02: compile-time error
          ) =>
      a;

  var _handler = null;

  // Expect compile-time error as no default values
  // are allowed in closure type.
  void InstallCallback(
      void cb({String msg
    : null //# 03: compile-time error
          })) {
    _handler = cb;
  }
}

main() {
  // Expect compile-time error due to missing comma in function definition.
  NamedParametersAggregatedTests.f_missing_comma(10
    , 25 //# 02: continued
      );

  // Expect compile-time erorr due to duplicate named argument.
  NamedParametersAggregatedTests.F31(10, b: 25
    , b:35 //# 04: compile-time error
    , b:35, b:45 //# 06: compile-time error
      );

  // Expect compile-time error due to missing positional argument.
  Expect.throws(() => NamedParametersAggregatedTests.F31(b:25, c:35), (e) => e is NoSuchMethodError); //# 05: static type warning

  new TypeTester<Callback>();

  (new NamedParametersAggregatedTests()).InstallCallback(null);
}
