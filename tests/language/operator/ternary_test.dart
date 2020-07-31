// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing the ternary operator.

import "package:expect/expect.dart";

class TernaryTest {
  static true_cond() {
    return true;
  }

  static false_cond() {
    return false;
  }

  static foo() {
    return -4;
  }

  static moo() {
    return 5;
  }

  static testMain() {
    Expect.equals(
        -4, (TernaryTest.true_cond() ? TernaryTest.foo() : TernaryTest.moo()));
    Expect.equals(
        5, (TernaryTest.false_cond() ? TernaryTest.foo() : TernaryTest.moo()));
  }
}

main() {
  TernaryTest.testMain();
}
