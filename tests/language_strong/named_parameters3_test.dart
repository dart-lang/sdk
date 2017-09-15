// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.
// Specifying named argument for not existing named parameter is run time error.

import "package:expect/expect.dart";

int test(int a, [int b]) {
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
