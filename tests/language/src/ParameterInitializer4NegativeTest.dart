// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Fails because this.x parameter is used in a static function.

class Foo {
  var x;
  static foo(this.x) {
  }
}


class ParameterInitializer4NegativeTest {
  static testMain() {
    Foo.foo();
  }
}

main() {
  ParameterInitializer4NegativeTest.testMain();
}
