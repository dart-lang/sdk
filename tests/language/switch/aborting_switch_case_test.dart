// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to be confused when inlining
// method that always aborts in a switch case.

import "package:expect/expect.dart";

foo() {
  throw 42;
}

main() {
  var exception;
  try {
    switch (42) {
      case 42:
        foo();
        foo();
        break;
    }
  } catch (e) {
    exception = e;
  }
  Expect.equals(42, exception);
}
