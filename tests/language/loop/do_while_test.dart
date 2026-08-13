// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing do while statement.

import "package:expect/expect.dart";

class Helper {
  static int f1(bool b) {
    do return 1; while (b);
    return 2;
  }

  static int f2(bool b) {
    do {
      return 1;
    } while (b);
    return 2;
  }

  static int f3(bool b) {
    do ; while (b);
    return 2;
  }

  static int f4(bool b) {
    do {} while (b);
    return 2;
  }

  static int f5(int n) {
    int i = 0;
    do {
      i++;
    } while (i < n);
    return i;
  }
}

class DoWhileTest {
  static testMain() {
    Expect.equals(1, Helper.f1(true));
    Expect.equals(1, Helper.f1(false));
    Expect.equals(1, Helper.f2(true));
    Expect.equals(1, Helper.f2(false));
    Expect.equals(2, Helper.f3(false));
    Expect.equals(2, Helper.f4(false));
    Expect.equals(1, Helper.f5(-2));
    Expect.equals(1, Helper.f5(-1));
    Expect.equals(1, Helper.f5(0));
    Expect.equals(1, Helper.f5(1));
    Expect.equals(2, Helper.f5(2));
    Expect.equals(3, Helper.f5(3));
  }
}

main() {
  DoWhileTest.testMain();
}
