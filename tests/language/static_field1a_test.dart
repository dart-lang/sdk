// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that a static method cannot be read as an instance field.

class Foo {
  Foo() {}
  static void m() {}
}

class StaticField1aTest {
  static testMain() {
    if (false) {
      var foo = new Foo();
      var m = foo.m;
    }
  }
}

main() {
  StaticField1aTest.testMain();
}
