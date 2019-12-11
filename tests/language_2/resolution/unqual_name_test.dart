// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to check that we can resolve unqualified identifiers

import "package:expect/expect.dart";

class B {
  B(x, y) : b = y {}
  var b;

  get_b() {
    // Resolving unqualified instance method.
    return really_really_get_it();
  }

  really_really_get_it() {
    return 5;
  }
}

class UnqualNameTest {
  static eleven() {
    return 11;
  }

  static testMain() {
    var o = new B(3, 5);
    Expect.equals(11, eleven()); // Unqualified static method call.
    Expect.equals(5, o.get_b());

    // Check whether we handle variable initializers correctly.
    var a = 1, x, b = a + 3;
    Expect.equals(5, a + b);
  }
}

main() {
  UnqualNameTest.testMain();
}
