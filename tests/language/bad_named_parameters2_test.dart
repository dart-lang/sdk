// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing bad named parameters.

import "package:expect/expect.dart";

class BadNamedParameters2Test {
  int foo(int a) {
    // Although no optional named parameters are declared, we must check that
    // no named arguments are passed in, either here or in the resolving stub.
    return a;
  }

  static testMain() {
    BadNamedParameters2Test np = new BadNamedParameters2Test();

    // Verify that NoSuchMethod is called after an error is detected.
    bool caught;
    try {
      caught = false;
      // No formal parameter named b.
      np.foo(b:25); // //# 01: static type warning
    } on NoSuchMethodError catch (e) {
      caught = true;
    }
    Expect.equals(true, caught); //# 01: continued
  }
}

main() {
  BadNamedParameters2Test.testMain();
}
