// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Redirection constructors must not initialize any fields.

class A {
  var x;
  A(this.x) {}
  A.named(this.x) : this(3) {}
}

class ConstructorRedirect4NegativeTest {
  static testMain() {
    new A.named(10);
  }
}

main() {
  ConstructorRedirect4NegativeTest.testMain();
}
