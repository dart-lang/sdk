// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// @dart=2.19

import "package:expect/expect.dart";

// Test that a case with an empty block does not fall through.

// VMOptions=
// VMOptions=--force-switch-dispatch-type=0
// VMOptions=--force-switch-dispatch-type=1
// VMOptions=--force-switch-dispatch-type=2

class EmptyBlockCaseTest {
  static testMain() {
    var exception = null;
    switch (1) {
      case 1: /*@compile-error=unspecified*/
        {}
      case 2:
        Expect.equals(true, false);
    }
  }
}

main() {
  EmptyBlockCaseTest.testMain();
}
