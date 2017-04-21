// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for function passing.

import "package:expect/expect.dart";

class FunctionArgumentTest {
  static testMe(Function f) {
    return f();
  }

  static void testMain() {
    Expect.equals(42, testMe(() {
      return 42;
    }));
  }
}

main() {
  FunctionArgumentTest.testMain();
}
