// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for closures.

import "package:expect/expect.dart";

class A {
  var field;
  A(this.field) {}
}

class ClosureTest {
  static testMain() {
    var o = new A(3);
    foo() => o.field++;
    Expect.equals(3, foo());
    Expect.equals(4, o.field);
  }
}

main() {
  ClosureTest.testMain();
}
