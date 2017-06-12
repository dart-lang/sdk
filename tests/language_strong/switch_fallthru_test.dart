// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that FallThroughError is thrown if switch clause does not terminate.

import "package:expect/expect.dart";

class SwitchFallthruTest {
  static String test(int n) {
    String result = "foo";
    switch (n) {
      case 0:
        result = "zero";
        break;
      case 1:
        result = "one";
      // fall-through, throw implicit FallThroughError here.
      case 9:
        result = "nine";
      // No implicit FallThroughError at end of switch statement.
    }
    return result;
  }

  static testMain() {
    Expect.equals("zero", test(0));
    bool fallthroughCaught = false;
    try {
      test(1);
    } on FallThroughError catch (e) {
      fallthroughCaught = true;
    }
    Expect.equals(true, fallthroughCaught);
    Expect.equals("nine", test(9));
    Expect.equals("foo", test(99));
  }
}

main() {
  SwitchFallthruTest.testMain();
}
