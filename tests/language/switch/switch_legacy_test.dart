// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.19

// Test legacy forms of switch statement.

// VMOptions=
// VMOptions=--force-switch-dispatch-type=0
// VMOptions=--force-switch-dispatch-type=1
// VMOptions=--force-switch-dispatch-type=2

import "package:expect/expect.dart";

const int ic1 = 1;
const int ic2 = 2;
void testSwitchIntExpression(int input, int? expect) {
  int? result = null;
  switch (input) {
    case 1 + 1: // 2
    case ic1 + 2: // 3
      result = 11;
      break;
    case ic2 * 2: // 4
    case 1 * 5: // 5
      result = 21;
      break;
    case ic1 % ic2 + 5: // 6
      result = 31;
      break;
  }
  Expect.equals(expect, result);
}

main() {
  testSwitchIntExpression(2, 11);
  testSwitchIntExpression(3, 11);
  testSwitchIntExpression(4, 21);
  testSwitchIntExpression(5, 21);
  testSwitchIntExpression(6, 31);
  testSwitchIntExpression(7, null);
}
