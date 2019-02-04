// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  test(literal, number) {
    Expect.equals(literal, number);
    Expect.identical(literal, number);
  }

  test(0, 0 + 0);
  test(1, 1 + 0);
  test(2, 1 + 1);
  test(3, -1 + 4);
  test(3, 4 + -1);

  test(-0, -(0));
  test(-3, -(3));

  test(1, 1 - 0);
  test(0, 1 - 1);
  test(1, 2 - 1);
  test(2, 4 - 2);
  test(-2, 2 - 4);

  test(0, 3 * 0);
  test(0, 0 * 3);
  test(1, 1 * 1);
  test(5, 5 * 1);
  test(15, 3 * 5);
  test(-1, 1 * -1);
  test(-15, -5 * 3);
  test(15, -5 * -3);

  test(1, 2 ~/ 2);
  test(2, 2 ~/ 1);
  test(2, 4 ~/ 2);
  test(2, 5 ~/ 2);
  test(-2, -5 ~/ 2);
  test(-2, -4 ~/ 2);
  test(-2, 5 ~/ -2);
  test(-2, 4 ~/ -2);

  test(3, 7 % 4);
  test(2, 9 % 7);
  test(2, -7 % 9);
  test(7, 7 % -9);
  test(7, 7 % 9);
  test(2, -7 % -9);

  test(3, (7).remainder(4));
  test(2, (9).remainder(7));
  test(-7, (-7).remainder(9));
  test(7, (7).remainder(-9));
  test(7, (7).remainder(9));
  test(-7, (-7).remainder(-9));
}
