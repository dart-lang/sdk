// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing dynamic calls.

import "package:expect/expect.dart";

class Helper {
  Helper() {}
  int foo(int i) {
    return i;
  }
}

class DynamicCallTest {
  static int testMain() {
    Helper obj = new Helper();
    Expect.equals(1, obj.foo(1));
  }
}

main() {
  DynamicCallTest.testMain();
}
