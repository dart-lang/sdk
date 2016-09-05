// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that a static field cannot be set as an instance field.

class Foo {
  Foo() {}
  static var x;
}

class StaticField2Test {
  static testMain() {
    if (false) {
      var foo = new Foo();
      foo.x = 1;
    }
  }
}

main() {
  StaticField2Test.testMain();
}
