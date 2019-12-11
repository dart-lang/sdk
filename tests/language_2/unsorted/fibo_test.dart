// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program calculating the Fibonacci sequence.

import "package:expect/expect.dart";

class Helper {
  static int fibonacci(int n) {
    int a = 0, b = 1, i = 0;
    while (i++ < n) {
      a = a + b;
      b = a - b;
    }
    return a;
  }
}

class FiboTest {
  static testMain() {
    Expect.equals(0, Helper.fibonacci(0));
    Expect.equals(1, Helper.fibonacci(1));
    Expect.equals(1, Helper.fibonacci(2));
    Expect.equals(2, Helper.fibonacci(3));
    Expect.equals(3, Helper.fibonacci(4));
    Expect.equals(5, Helper.fibonacci(5));
    Expect.equals(102334155, Helper.fibonacci(40));
  }
}

main() {
  FiboTest.testMain();
}
