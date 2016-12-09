// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing for statement.

import "package:expect/expect.dart";

class Helper {
  static int f1() {
    for (;;) return 1;
  }

  static int f2(var n) {
    int i = 0;
    for (; i < n; i++);
    return i;
  }

  static int f3(int n) {
    int i = 0;
    for (int j = 0; j < n; j++) i = i + j + 1;
    return i;
  }

  static int f4(n) {
    int i = 0;
    for (bool stop = false; (i < n) && !stop; i++) {
      if (i >= 5) {
        stop = true;
      }
    }
    return i;
  }

  static var status;
  static void f5() {
    status = 0;
    for (var stop = false;;) {
      if (stop) {
        break;
      } else {
        stop = true;
        continue;
      }
    }
    status = 1;
  }

  static int f6() {
    // Verify that side effects in the condition are visible after the loop.
    int i = 0;
    for (; ++i < 3; ) {}
    return i;
  }
}

class ForTest {
  static testMain() {
    Expect.equals(1, Helper.f1());
    Expect.equals(0, Helper.f2(-1));
    Expect.equals(0, Helper.f2(0));
    Expect.equals(10, Helper.f2(10));
    Expect.equals(0, Helper.f3(-1));
    Expect.equals(0, Helper.f3(0));
    Expect.equals(1, Helper.f3(1));
    Expect.equals(3, Helper.f3(2));
    Expect.equals(6, Helper.f3(3));
    Expect.equals(10, Helper.f3(4));
    Expect.equals(0, Helper.f4(-1));
    Expect.equals(0, Helper.f4(0));
    Expect.equals(1, Helper.f4(1));
    Expect.equals(6, Helper.f4(6));
    Expect.equals(6, Helper.f4(10));

    Helper.f5();
    Expect.equals(1, Helper.status);

    Expect.equals(3, Helper.f6());
  }
}

main() {
  ForTest.testMain();
}
