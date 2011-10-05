// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Missing call to super.

class A {
  A() {}
}

class B extends A {
  // Missing call to super.
  B() {}
}

class SuperNegativeTest {
  static testMain() {
    var b = new B();
  }
}

main() {
  SuperNegativeTest.testMain();
}
