// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that a static field cannot be read as an instance field.

class Foo {
  Foo() {}
  static var x;
}

class StaticField1Test {
  static testMain() {
    if (false) {
      var foo = new Foo();
      var x = foo.x; //# 01: compile-time error
    }
  }
}

main() {
  StaticField1Test.testMain();
}
