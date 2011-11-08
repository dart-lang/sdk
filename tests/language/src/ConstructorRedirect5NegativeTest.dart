// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Redirection constructors must not call any super constructors.

class A {
  var x;
  A(this.x) {}
  A.named(x) : this(3), super() {}
}

class ConstructorRedirect5NegativeTest {
  static testMain() {
    new A.named(10);
  }
}

main() {
  ConstructorRedirect5NegativeTest.testMain();
}
