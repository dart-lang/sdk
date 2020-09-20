// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test integer div by zero.

import "package:expect/expect.dart";

class DivByZeroTest {
  static double divBy(int a, int b) {
    var result = a / b;
    return 1.0 * result;
  }

  static bool moustacheDivBy(int a, int b) {
    var val = null;
    try {
      val = a ~/ b;
    } catch (e) {
      return true;
    }
    print("Should not have gotten: $val");
    return false;
  }

  static void testMain() {
    Expect.isTrue(divBy(0, 0).isNaN);
    Expect.isTrue(moustacheDivBy(0, 0));
  }
}

main() {
  DivByZeroTest.testMain();
}
