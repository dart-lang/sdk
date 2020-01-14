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
      return i; // Value of i on return is 1.
    } finally {
      i = i + 800; // Should get executed on return.
    }
    return i + 200; // Should not get executed.
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

class ExecuteFinally1Test {
  static testMain() {
    Helper obj = new Helper();
    Expect.equals(1, obj.f1());
    Expect.equals(801, obj.i);
  }
}

main() {
  ExecuteFinally1Test.testMain();
}
