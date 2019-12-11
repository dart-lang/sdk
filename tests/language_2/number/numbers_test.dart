// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test number types.

library NumbersTest.dart;

import "package:expect/expect.dart";

class NumbersTest {
  static double testMain() {
    var one = 1;
    Expect.equals(true, one is Object);
    Expect.equals(true, one is num);
    Expect.equals(true, one is int);
    Expect.equals(false, one is double);

    var two = 2.0;
    Expect.equals(true, two is Object);
    Expect.equals(true, two is num);
    Expect.equals(false, two is int);
    Expect.equals(true, two is double);

    var result = one + two;
    Expect.equals(true, result is Object);
    Expect.equals(true, result is num);
    Expect.equals(false, result is int);
    Expect.equals(true, result is double);

    Expect.equals(3.0, result);
    return result;
  }
}

main() {
  NumbersTest.testMain();
}
