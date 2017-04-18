// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--generic-method-syntax

/// Dart test verifying that the parser can handle type parameterization of
/// local function declarations, and declarations of function parameters.

library generic_local_functions_test;

import "package:expect/expect.dart";

// Declare a generic function parameter.
int f(Y g<X, Y>(Map<X, Y> arg, X x)) => g<int, int>(<int, int>{1: 42}, 1);

main() {
  // Declare a generic local function
  Y h<X, Y>(Map<X, Y> m, X x) => m[x];
  // Pass a generic local function as an argument.
  Expect.equals(f(h), 42);
  // Pass a function expression as an argument.
  Expect.equals(f(<X, Y>(Map<X, Y> m, X x) => m[x]), 42);
}
