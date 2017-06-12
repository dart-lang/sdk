// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

class IntTest {
  static void testMain() {
    Expect.equals(0, 0 + 0);
    Expect.equals(1, 1 + 0);
    Expect.equals(2, 1 + 1);
    Expect.equals(3, -1 + 4);
    Expect.equals(3, 4 + -1);

    Expect.equals(1, 1 - 0);
    Expect.equals(0, 1 - 1);
    Expect.equals(1, 2 - 1);
    Expect.equals(2, 4 - 2);
    Expect.equals(-2, 2 - 4);

    Expect.equals(0, 3 * 0);
    Expect.equals(0, 0 * 3);
    Expect.equals(1, 1 * 1);
    Expect.equals(5, 5 * 1);
    Expect.equals(15, 3 * 5);
    Expect.equals(-1, 1 * -1);
    Expect.equals(-15, -5 * 3);
    Expect.equals(15, -5 * -3);

    Expect.equals(1, 2 ~/ 2);
    Expect.equals(2, 2 ~/ 1);
    Expect.equals(2, 4 ~/ 2);
    Expect.equals(2, 5 ~/ 2);
    Expect.equals(-2, -5 ~/ 2);
    Expect.equals(-2, -4 ~/ 2);
    Expect.equals(-2, 5 ~/ -2);
    Expect.equals(-2, 4 ~/ -2);

    Expect.equals(3, 7 % 4);
    Expect.equals(2, 9 % 7);
    Expect.equals(2, -7 % 9);
    Expect.equals(7, 7 % -9);
    Expect.equals(7, 7 % 9);
    Expect.equals(2, -7 % -9);

    Expect.equals(3, (7).remainder(4));
    Expect.equals(2, (9).remainder(7));
    Expect.equals(-7, (-7).remainder(9));
    Expect.equals(7, (7).remainder(-9));
    Expect.equals(7, (7).remainder(9));
    Expect.equals(-7, (-7).remainder(-9));
  }
}

main() {
  IntTest.testMain();
}
