// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test a new statement by itself.

import "package:expect/expect.dart";

class A {
  int a;
  int b;
  static int c;
  static int d;

  A(int x, int y)
      : a = x,
        b = y {
    A.c = x;
    A.d = y;
  }
}

class NewStatementTest {
  static testMain() {
    new A(10, 20);
    Expect.equals(10, A.c);
    Expect.equals(20, A.d);
  }
}

main() {
  NewStatementTest.testMain();
}
