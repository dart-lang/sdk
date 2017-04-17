// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test. Fields can be invoked directly if they are unqualified.

class A {
  var foo;
  A() {
    foo = () {};
  }
  void bar() {
    foo(); // <= foo is a field, but can still be invoked without parenthesis.
  }
}

class FieldMethodTest {
  static testMain() {
    new A().bar();
  }
}

main() {
  FieldMethodTest.testMain();
}
