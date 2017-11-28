// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Fails because this.x parameter is used in a setter.

class Foo {
  var x;
  Foo() {}
  set y(this.x) {
  }
}


class ParameterInitializer2NegativeTest {
  static testMain() {
    (new Foo()).y = 2;
  }
}

main() {
  ParameterInitializer2NegativeTest.testMain();
}
