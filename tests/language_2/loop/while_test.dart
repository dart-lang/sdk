// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing while statement.

import "package:expect/expect.dart";

class Helper {
  static int f1(bool b) {
    while (b) return 1;

    return 2;
  }

  static int f2(bool b) {
    while (b) {
      return 1;
    }
    return 2;
  }

  static int f3(int n) {
    int i = 0;
    while (i < n) {
      i++;
    }
    return i;
  }

  static int f4() {
    // Verify that side effects in the condition are visible after the loop.
    int i = 0;
    while (++i < 3) {}
    return i;
  }
}

class WhileTest {
  static testMain() {
    Expect.equals(1, Helper.f1(true));
    Expect.equals(2, Helper.f1(false));
    Expect.equals(1, Helper.f2(true));
    Expect.equals(2, Helper.f2(false));
    Expect.equals(0, Helper.f3(-2));
    Expect.equals(0, Helper.f3(-1));
    Expect.equals(0, Helper.f3(0));
    Expect.equals(1, Helper.f3(1));
    Expect.equals(2, Helper.f3(2));
    Expect.equals(3, Helper.f4());
  }
}

main() {
  WhileTest.testMain();
}
