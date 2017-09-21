// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that a case with an empty block does not fall through.

class EmptyBlockCaseTest {
  static testMain() {
    var exception = null;
    try {
      switch (1) {
        case 1: /*@compile-error=unspecified*/
          {}
        case 2:
          Expect.equals(true, false);
      }
    } on FallThroughError catch (e) {
      exception = e;
    }
    Expect.equals(true, exception != null);
  }
}

main() {
  EmptyBlockCaseTest.testMain();
}
