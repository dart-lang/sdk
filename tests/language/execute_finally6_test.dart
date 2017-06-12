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
      try {
        int j;
        j = func();
        L1:
        while (i <= 0) {
          if (i == 0) {
            try {
              i = 1;
              func();
              try {
                int j;
                j = func();
                L1:
                while (j < 50) {
                  j += func();
                  if (j > 30) {
                    break L1; // Break out of nested try blocks.
                  }
                }
                i += 200000; // Should get executed.
              } finally {
                i = i + 200; // Should get executed as normal control flow.
              }
            } finally {
              i = i + 400; // Should get executed as normal control flow.
            }
          }
        }
      } finally {
        i = i + 800; // Should get executed as normal control flow.
      }
      return i; // Value of i should be 201401.
    } finally {
      i = i + 1600; // Should get executed as part of return above.
    }
    i = i + 2000000; // Should not get executed.
    return 1;
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

class ExecuteFinally6Test {
  static testMain() {
    Helper obj = new Helper();
    Expect.equals(201401, obj.f1());
    Expect.equals(203001, obj.i);
  }
}

main() {
  ExecuteFinally6Test.testMain();
}
