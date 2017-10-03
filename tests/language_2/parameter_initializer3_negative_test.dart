// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Fails because this.x parameter is used in a factory.

class Foo {
  var x;
  factory Foo(this.x) {
    return new Foo.named();
  }
  Foo.named() {}
}

class ParameterInitializer3NegativeTest {
  static testMain() {
    new Foo(2);
  }
}

main() {
  ParameterInitializer3NegativeTest.testMain();
}
