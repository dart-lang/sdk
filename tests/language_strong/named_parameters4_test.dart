// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.
// Specifying named argument for not existing named parameter is run time error.

import "package:expect/expect.dart";

// This test is very similar to NamedParameters3Test, but exercises a
// different corner case in the frog compiler. frog wasn't detecting unused
// named arguments when no other arguments were expected. So, this test
// purposely passes the exact number of positional parameters.

int test(int a) {
  return a;
}

main() {
  bool foundError = false;
  try {
    test(10, x: 99); // 1 positional arg, as expected. Param x does not exist.
  } on NoSuchMethodError catch (e) {
    foundError = true;
  }
  Expect.equals(true, foundError);
}
