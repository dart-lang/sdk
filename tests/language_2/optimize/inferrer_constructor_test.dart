// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js type inferrer detects dead code.

import "package:expect/expect.dart";

class A {
  var field;
  A(test) {
    if (test) {
      return;
      field = 42;
    } else {
      field = 54;
    }
  }
}

main() {
  var a = new A(true);
  Expect.throwsNoSuchMethodError(() => a.field + 42);
}
