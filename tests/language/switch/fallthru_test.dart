// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that FallThroughError is thrown if switch clause does not terminate.

import "package:expect/expect.dart";

String test(int n) {
  String result = "foo";
  switch (n) {
    case 0:
      result = "zero";
      break;
    case 1:
//  ^^^^
// [analyzer] COMPILE_TIME_ERROR.SWITCH_CASE_COMPLETES_NORMALLY
// [cfe] Switch case may fall through to the next case.
      result = "one";
  // fall-through, error if case is non-empty
    case 9:
      result = "nine";
  // No implicit FallThroughError at end of switch statement.
  }
  return result;
}

main() {
  Expect.equals("zero", test(0));
  Expect.equals("nine", test(1));
  Expect.equals("nine", test(9));
  Expect.equals("foo", test(99));
}
