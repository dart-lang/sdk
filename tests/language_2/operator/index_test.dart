// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing index operators.

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

class IndexTest {
  static const ID_IDLE = 0;

  static testMain() {
    var a = new List(10);
    Expect.equals(10, a.length);
    for (int i = 0; i < a.length; i++) {
      a[i] = Helper.fibonacci(i);
    }
    a[ID_IDLE] = Helper.fibonacci(0);
    for (int i = 2; i < a.length; i++) {
      Expect.equals(a[i - 2] + a[i - 1], a[i]);
    }
    Expect.equals(515, a[3] = 515);
  }
}

main() {
  IndexTest.testMain();
}
