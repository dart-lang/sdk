// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test error for overriding method with setter.

class A {
  foo(x) { }
}

class B extends A {
  set foo(x) { }  // setter cannot override method.
}

class OverrideFieldMethod6NegativeTest {
  static testMain() {
    new B().foo = 10;
  }
}

main() {
  OverrideFieldMethod6NegativeTest.testMain();
}
