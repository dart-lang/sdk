// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing params.

import "package:expect/expect.dart";

class Helper {
  static int foo(int i) {
    var b;
    b = i + 1;
    return b;
  }
}

class ParamTest {
  static testMain() {
    Expect.equals(2, Helper.foo(1));
  }
}

main() {
  ParamTest.testMain();
}
