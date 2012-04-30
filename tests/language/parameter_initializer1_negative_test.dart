// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Fails because this.x parameter is used in a function.

class Foo {
  var x;
  Foo() {}
  foo(this.x) {
  }
}


class ParameterInitializer1NegativeTest {
  static testMain() {
    new Foo().foo(2);
  }
}

main() {
  ParameterInitializer1NegativeTest.testMain();
}
