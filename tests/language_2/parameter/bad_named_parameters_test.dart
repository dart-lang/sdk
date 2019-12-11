// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing bad named parameters.

import "package:expect/expect.dart";

class BadNamedParametersTest {
  int f42(int a, {int b: 20, int c: 30}) {
    return 100 * (100 * a + b) + c;
  }

  int f52(int a, {int b: 20, int c, int d: 40}) {
    return 100 * (100 * (100 * a + b) + (c == null ? 0 : c)) + d;
  }
}

main() {
  BadNamedParametersTest np = new BadNamedParametersTest();

  // Parameter b passed twice.
  np.f42(10, 25, b: 25);
  //    ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED
  // [cfe] Too many positional arguments: 1 allowed, but 2 found.

  // Parameter x does not exist.
  np.f42(10, 25, x: 99);
  //    ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED
  // [cfe] Too many positional arguments: 1 allowed, but 2 found.
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_NAMED_PARAMETER

  // Parameter b1 does not exist.
  np.f52(10, b: 25, b1: 99, c: 35);
  //                ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_NAMED_PARAMETER
  // [cfe] No named parameter with the name 'b1'.

  // Too many parameters.
  np.f42(10, 20, 30, 40);
  //    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED
  // [cfe] Too many positional arguments: 1 allowed, but 4 found.

  // Too few parameters.
  np.f42(b: 25);
  //    ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
  // [cfe] Too few positional arguments: 1 required, 0 given.
}
