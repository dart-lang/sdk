// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we correctly intercept super getter and setter calls.

import "package:expect/expect.dart";

var expected;

class A {
  set length(a) {
    Expect.equals(expected, a);
  }

  get length => 41;
}

class B extends A {
  test() {
    expected = 42;
    Expect.equals(42, super.length = 42);
    expected = 42;
    Expect.equals(42, super.length += 1);
    expected = 42;
    Expect.equals(42, ++super.length);
    expected = 40;
    Expect.equals(40, --super.length);
    expected = 42;
    Expect.equals(41, super.length++);
    expected = 40;
    Expect.equals(41, super.length--);
    Expect.equals(41, super.length);
  }
}

main() {
  // Ensures the list class is instantiated.
  print([]);
  new B().test();
}
