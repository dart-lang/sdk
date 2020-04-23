// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class OperatorTest {
  static int i1, i2;

  OperatorTest() {}

  static testMain() {
    var op1 = new Operator(1);
    var op2 = new Operator(2);
    Expect.equals(~1, ~op1);
  }
}

class Operator {
  int value;

  Operator(int i) {
    value = i;
  }

  operator ~() {
    return ~value;
  }
}

main() {
  OperatorTest.testMain();
}
