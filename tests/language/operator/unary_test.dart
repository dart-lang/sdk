// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test for testing binary operations.

class UnaryTest {
  static foo() {
    return 4;
  }

  static moo() {
    return 5;
  }

  static testMain() {
    Expect.equals(9.0, (UnaryTest.foo() + UnaryTest.moo()));
  }
}

main() {
  UnaryTest.testMain();
}
