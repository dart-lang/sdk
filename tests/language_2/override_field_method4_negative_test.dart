// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test error for overriding method with field.

class A {
  foo() {}
}

class B extends A {
  var foo; // Field cannot override method.
}

class OverrideFieldMethod4NegativeTest {
  static testMain() {
    print(new B().foo);
  }
}

main() {
  OverrideFieldMethod4NegativeTest.testMain();
}
