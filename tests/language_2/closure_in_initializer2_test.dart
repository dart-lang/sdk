// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a parameter used in a closure is properly boxed.

import "package:expect/expect.dart";

abstract class S {
  S() {
    Expect.equals(2, this.f());
  }

  get f;
}

class A extends S {
  var f;
  A(a) : f = (() => ++a) {
    Expect.equals(a, 2);
  }
}

main() {
  var a = new A(1);
  Expect.equals(a.f(), 3);
}
