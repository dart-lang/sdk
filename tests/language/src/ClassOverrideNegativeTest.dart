// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check fail because incompatible overriding method

class A {
  foo() {}
}

class B extends A {
  foo(a) { }
}

class ClassOverrideNegativeTest {
  static testMain() {
  }
}

main() {
  ClassOverrideNegativeTest.testMain();
}
