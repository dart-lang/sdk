// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program which shows how to write self verifying tests
// and how to print dart objects if needed.

import "package:expect/expect.dart";

class Helper {
  static int foo(int i) {
    return i + 10;
  }
}

class NativeTest {
  static testMain() {
    int i = 10;
    int result = 10 + 10 + 10;
    i = Helper.foo(i + 10);
    print("$i is result.");
    Expect.equals(i, result);
  }
}

main() {
  NativeTest.testMain();
}
