// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test error for overriding getter with method.

class A {
  get foo {
    return 123;
  }
}

class B extends A {
  foo() {} // method cannot override getter.
}

class OverrideFieldMethod2NegativeTest {
  static testMain() {
    new B().foo();
  }
}

main() {
  OverrideFieldMethod2NegativeTest.testMain();
}
