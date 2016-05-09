// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart test verifying that the parser can handle type parameterization of
/// local function declarations, and declarations of function parameters.

library generic_functions_test;

import "package:expect/expect.dart";

// Declare a generic function parameter.
String f(int g<X, Y>(Map<X, Y> arg)) => null;

main() {
  // Declare a generic local function
  int h<X extends Y, Y>(Map<X, Y> arg) => null;
  // Pass a generic local function as an argument.
  f(h);
  // Pass a function expression as an argument.
  f(<X, Y super X>(Map<X, Y> arg) => 42);
}
