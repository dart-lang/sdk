// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Second dart test program.

import "package:expect/expect.dart";

class Helper {
  static empty() {}
  static int foo() {
    return 42;
  }
}

class SecondTest {
  static testMain() {
    Helper.empty();
    Expect.equals(42, Helper.foo());
  }
}

main() {
  SecondTest.testMain();
}
