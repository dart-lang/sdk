// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test error for overriding field with method.

class A {
  var foo;
}

class B extends A {
  foo() {} // method cannot override field.
}

class OverrideFieldMethod1NegativeTest {
  static testMain() {
    new B().foo();
  }
}

main() {
  OverrideFieldMethod1NegativeTest.testMain();
}
