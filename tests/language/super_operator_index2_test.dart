// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for super indexing operations.

import "package:expect/expect.dart";

class A {
  var map = new Map();
  operator []=(a, b) {
    map[a] = b;
  }

  operator [](a) => map[a];
}

class B extends A {
  foo() {
    super[4] = 42;
    Expect.equals(42, super[4]);
    super[4] += 5;
    Expect.equals(47, super[4]);
  }
}

main() {
  new B().foo();
}
