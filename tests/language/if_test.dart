// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing if statement.

import "package:expect/expect.dart";

class Helper {
  static int f0(bool b) {
    if (b) ;
    if (b)
      ;
    else
      ;
    if (b) {}
    if (b) {} else {}
    return 0;
  }

  static int f1(bool b) {
    if (b)
      return 1;
    else
      return 2;
  }

  static int f2(bool b) {
    if (b) {
      return 1;
    } else {
      return 2;
    }
  }

  static int f3(bool b) {
    if (b) return 1;
    return 2;
  }

  static int f4(bool b) {
    if (b) {
      return 1;
    }
    return 2;
  }

  static int f5(bool b) {
    if (!b) {
      return 1;
    }
    return 2;
  }

  static int f6(bool a, bool b) {
    if (a || b) {
      return 1;
    }
    return 2;
  }

  static int f7(bool a, bool b) {
    if (a && b) {
      return 1;
    }
    return 2;
  }
}

class IfTest {
  static testMain() {
    Expect.equals(0, Helper.f0(true));
    Expect.equals(1, Helper.f1(true));
    Expect.equals(2, Helper.f1(false));
    Expect.equals(1, Helper.f2(true));
    Expect.equals(2, Helper.f2(false));
    Expect.equals(1, Helper.f3(true));
    Expect.equals(2, Helper.f3(false));
    Expect.equals(1, Helper.f4(true));
    Expect.equals(2, Helper.f4(false));
    Expect.equals(2, Helper.f5(true));
    Expect.equals(1, Helper.f5(false));
    Expect.equals(1, Helper.f6(true, true));
    Expect.equals(1, Helper.f6(true, false));
    Expect.equals(1, Helper.f6(false, true));
    Expect.equals(2, Helper.f6(false, false));
    Expect.equals(1, Helper.f7(true, true));
    Expect.equals(2, Helper.f7(true, false));
    Expect.equals(2, Helper.f7(false, true));
    Expect.equals(2, Helper.f7(false, false));
  }
}

main() {
  IfTest.testMain();
}
