// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Operator dart test program.

import "package:expect/expect.dart";

class Helper {
  int i;
  Helper(int val) : i = val {}
  operator [](int index) {
    return i + index;
  }

  void operator []=(int index, int val) {
    i = val;
  }
}

class OperatorTest {
  static testMain() {
    Helper obj = new Helper(10);
    Expect.equals(10, obj.i);
    obj[10] = 20;
    Expect.equals(30, obj[10]);
  }
}

main() {
  OperatorTest.testMain();
}
