// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for capturing.

import "package:expect/expect.dart";

class ContextTest {
  static foo(Function f) {
    return f();
  }

  static void testMain() {
    int x = 42;
    bar() {
      return x;
    }

    x++;
    Expect.equals(43, foo(bar));
  }
}

main() {
  ContextTest.testMain();
}
