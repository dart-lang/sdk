// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing factories.

class A {
  factory A(n) {
    return new A.internal(n);
  }
  A.internal(n) : n_ = n {}
  var n_;
}

class B {
  factory B.my() {
    return new B(3);
  }
  B(n) : n_ = n {}
  var n_;
}

class FactoryTest {
  static testMain() {
    new B.my();
    var b = new B.my();
    Expect.equals(3, b.n_);
    var a = new A(5);
    Expect.equals(5, a.n_);
  }
}

main() {
  FactoryTest.testMain();
}
