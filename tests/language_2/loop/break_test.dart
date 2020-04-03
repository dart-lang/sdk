// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for breaks in for, do/while and while loops.

import "package:expect/expect.dart";

class BreakTest {
  static testMain() {
    int i;
    int forCounter = 0;
    for (i = 0; i < 10; i++) {
      forCounter++;
      if (i > 3) break;
    }
    Expect.equals(5, forCounter);
    Expect.equals(4, i);

    i = 0;
    int doWhileCounter = 0;
    do {
      i++;
      doWhileCounter++;
      if (i > 3) break;
    } while (i < 10);
    Expect.equals(4, doWhileCounter);
    Expect.equals(4, i);

    i = 0;
    int whileCounter = 0;
    while (i < 10) {
      i++;
      whileCounter++;
      if (i > 3) break;
    }
    Expect.equals(4, whileCounter);
    Expect.equals(4, i);

    // Use a label to break to the outer loop.
    i = 0;
    L:
    while (i < 10) {
      i++;
      while (i > 5) {
        break L;
      }
    }
    Expect.equals(6, i);
  }
}

main() {
  BreakTest.testMain();
}
