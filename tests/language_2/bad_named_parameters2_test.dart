// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing bad named parameters.

class BadNamedParameters2Test {
  int foo(int a) {
    // Although no optional named parameters are declared, we must check that
    // no named arguments are passed in, either here or in the resolving stub.
    return a;
  }
}

main() {
  BadNamedParameters2Test np = new BadNamedParameters2Test();

  // No formal parameter named b.
  np.foo(b: 25); //# 01: compile-time error
}
