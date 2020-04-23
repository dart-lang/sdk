// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for branches. Make sure that shortcuts work, even if they have
// to jump over several expressions.

import "package:expect/expect.dart";

class BranchesTest {
  static bool f() {
    Expect.equals("Never reached", 0);
    return true;
  }

  static void testMain() {
    int checkPointCounter = 1;
    int checkPoint1 = 0;
    int checkPoint2 = 0;
    int checkPoint3 = 0;
    int checkPoint4 = 0;
    int checkPoint5 = 0;
    int checkPoint6 = 0;
    int i = 0;
    for (int i = 0; i < 2; i++) {
      if (i == 0) {
        checkPoint1 += checkPointCounter++;
        if (true || // Test branch-if-true.
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f() ||
            f()) {
          checkPoint2 += checkPointCounter++;
        }
      } else {
        // Test branch (jumping over the else branch).
        checkPoint3 += checkPointCounter++;
        if (false) {
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
          checkPoint4 = checkPointCounter++; // Never reached.
        }
      }
      checkPoint5 += checkPointCounter++;
    }
    checkPoint6 += checkPointCounter++;
    Expect.equals(1, checkPoint1);
    Expect.equals(2, checkPoint2);
    Expect.equals(4, checkPoint3);
    Expect.equals(0, checkPoint4);
    Expect.equals(8, checkPoint5);
    Expect.equals(6, checkPoint6);
  }
}

main() {
  BranchesTest.testMain();
}
