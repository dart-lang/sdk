// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test error for overriding method with getter.

class A {
  foo() {
    return 999;
  }
}

class B extends A {
  get foo {
    return 123;
  } // getter cannot override method
}

class OverrideFieldMethod5NegativeTest {
  static testMain() {
    print(new B().foo);
  }
}

main() {
  OverrideFieldMethod5NegativeTest.testMain();
}
