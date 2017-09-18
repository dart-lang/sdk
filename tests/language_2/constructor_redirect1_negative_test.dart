// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Redirection constructors must not be cyclic.

class A {
  var x;
  A(x) : this.named(x, 0); //# none: compile-time error
  A.named(x, int y) : this(x + y); //# 01: compile-time error
}

class ConstructorRedirect1NegativeTest {
  static testMain() {
    new A(10);
  }
}

main() {
  ConstructorRedirect1NegativeTest.testMain();
}
