// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing execution of finally blocks on
// control flow breaks because of 'return', 'continue' etc.

import "package:expect/expect.dart";

class Helper {
  Helper() : i = 0 {}

  int f1() {
    try {
      int j;
      j = func();
      i = 1;
    } finally {
      i = i + 10;
    }
    return i + 200; // Should return here with i = 211.
    try {
      int j;
      j = func();
    } finally {
      i = i + 10; // Should not get executed as part of return above.
    }
  }

  static int func() {
    int i = 0;
    while (i < 10) {
      i++;
    }
    return i;
  }

  int i;
}

class ExecuteFinally4Test {
  static testMain() {
    Helper obj = new Helper();
    Expect.equals(211, obj.f1());
    Expect.equals(11, obj.i);
  }
}

main() {
  ExecuteFinally4Test.testMain();
}
