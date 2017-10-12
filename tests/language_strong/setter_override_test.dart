// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we do not report a compile-time error when a static setter named
// foo= is declared in a class inheriting an instance method or getter named
// foo, and that we do report an error if an instance setter named foo= or
// instance field name foo is inherited.

import "package:expect/expect.dart";

class A {
  var foo = 42; // //# 00: compile-time error
  get foo => 42; // //# 01: static type warning
  foo() => 42; // //# 02: static type warning
  set foo(value) {} // //# 03: compile-time error
}

class B extends A {
  static var foo_;
  static set foo(value) {
    foo_ = value;
  }
}

main() {
  B.foo = 42;
  Expect.equals(42, B.foo_);
}
