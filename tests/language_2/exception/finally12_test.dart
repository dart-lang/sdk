// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to not treat the finally
// block as a successor of a nested try block.

import "package:expect/expect.dart";

var a;

foo() {
  var b = a == 8; // This should not be GVN'ed.
  while (!b) {
    try {
      try {} finally {
        a = 8;
        break;
      }
    } finally {
      return a == 8;
    }
  }
}

main() {
  Expect.isTrue(foo());
}
