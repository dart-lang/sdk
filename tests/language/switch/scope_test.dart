// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that a new scope is introduced for each switch case.

import "package:expect/expect.dart";

class SwitchScopeTest {
  static testMain() {
    switch (1) {
      case 1:
        final v = 1;
        break;
      case 2:
        final v = 2;
        Expect.equals(2, v);
        break;
      default:
        final v = 3;
        break;
    }
  }
}

main() {
  SwitchScopeTest.testMain();
}
