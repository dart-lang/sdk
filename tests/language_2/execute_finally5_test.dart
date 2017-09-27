// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing execution of finally blocks on
// control flow breaks because of 'return', 'continue' etc.

import "package:expect/expect.dart";

class Helper {
  Helper() : i = 0 {}

  int f1(int param) {
    if (param == 0) {
      try {
        int j;
        j = func();
        try {
          i = 1;
          return i; // Value of i is 1 on return.
        } finally {
          i = i + 400; // Should get executed when we return.
        }
        i = 2; // Should not get executed.
        return i;
      } finally {
        i = i + 800; // Should get executed when we return.
      }
      return i + 200; // Should not get executed.
    }
    try {
      int j;
      j = func();
      try {
        i = 4;
        return i; // Value of i is 1 on return.
      } finally {
        i = i + 100; // Should get executed when we return.
      }
      i = 2; // Should not get executed.
      return i;
    } finally {
      i = i + 200; // Should get executed when we return.
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

class ExecuteFinally5Test {
  static testMain() {
    Helper obj = new Helper();
    Expect.equals(1, obj.f1(0));
    Expect.equals(1201, obj.i);
    Expect.equals(4, obj.f1(1));
    Expect.equals(304, obj.i);
  }
}

main() {
  ExecuteFinally5Test.testMain();
}
