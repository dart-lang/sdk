// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing libraries.

library Library1Test.dart;

import "package:expect/expect.dart";
import "library1_lib.lib";

main() {
  Library1Test.testMain();
}

class Library1Test {
  static testMain() {
    var a = new A();
    String s = a.foo();
    Expect.equals(s, "foo-rty two");
  }
}
