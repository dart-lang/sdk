// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing binary operations.

import "package:expect/expect.dart";

class UnaryTest {
  static foo() {
    return -4;
  }

  static moo() {
    return 5;
  }

  static testMain() {
    Expect.equals(1, (UnaryTest.foo() + UnaryTest.moo()));
  }
}

main() {
  UnaryTest.testMain();
}
