// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Redirection constructors must not be cyclic.

class A {
  var x;
  A(x) : this(0); /*@compile-error=unspecified*/
}

class ConstructorRedirect2NegativeTest {
  static testMain() {
    new A(10);
  }
}

main() {
  ConstructorRedirect2NegativeTest.testMain();
}
