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

abstract class Link<T> {
  factory Link.create() = LinkFactory<T>.create;
  //                      ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
  // [cfe] Expected 0 type arguments.
  //                      ^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_INVALID_RETURN_TYPE
}

class LinkFactory {
  //   Compile time error: should be LinkFactory<T> to match abstract class above
  factory Link.create() {
  //      ^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_FACTORY_NAME_NOT_A_CLASS
  // [cfe] The name of a constructor must match the name of the enclosing class.
    return null;
  }
}


main() {
  FactoryTest.testMain();
  var a = new Link<int>.create();
  //          ^
  // [cfe] Expected 0 type arguments.
}
