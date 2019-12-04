// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.

class TypeTester<T> {}

// Expect compile-time error as no default values are allowed
// in closure type definitions.
typedef void Callback([String msg

]);

class NamedParametersAggregatedTests {
  static int F31(int a, {int b: 20, int c: 30}) {
    return 100 * (100 * a + b) + c;
  }

  static int f_missing_comma(a

  ) =>
  a;

  var _handler = null;

  // Expect compile-time error as no default values
  // are allowed in closure type.
  void InstallCallback(
      void cb({String msg

      })) {
    _handler = cb;
  }
}

main() {
  // Expect compile-time error due to missing comma in function definition.
  NamedParametersAggregatedTests.f_missing_comma(10

  );

  // Expect compile-time error due to duplicate named argument.
  NamedParametersAggregatedTests.F31(10, b: 25


  );

  // Expect compile-time error due to missing positional argument.


  new TypeTester<Callback>();

  (new NamedParametersAggregatedTests()).InstallCallback(null);
}
