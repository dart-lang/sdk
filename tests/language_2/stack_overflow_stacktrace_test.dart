// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart program testing stack overflow.

import "package:expect/expect.dart";

class StackOverflowTest {
  static void curseTheRecurse(a, b, c) {
    curseTheRecurse(b, c, a);
  }

  static void testMain() {
    bool exceptionCaught = false;
    try {
      curseTheRecurse(1, 2, 3);
    } on StackOverflowError catch (e, stacktrace) {
      String s = stacktrace.toString();
      Expect.equals(-1, s.indexOf("-1:-1"));
      exceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
  }
}

main() {
  StackOverflowTest.testMain();
}
