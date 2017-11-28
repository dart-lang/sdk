// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing factories.

import "package:expect/expect.dart";

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

// Test compile time error for factories with parameterized types.

abstract class Link<T> {// //# 00: continued
  factory Link.create() = LinkFactory<T>.create; // //# 00: compile-time error
}// //# 00: continued

class LinkFactory {// //# 00: continued
  //   Compile time error: should be LinkFactory<T> to match abstract class above
  factory Link.create() { //# 00: compile-time error
    return null;// //# 00: continued
  }// //# 00: continued
}// //# 00: continued


main() {
  FactoryTest.testMain();
  var a = new Link<int>.create(); //# 00: continued
}
