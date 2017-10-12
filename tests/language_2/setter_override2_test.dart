// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we do not report a compile-time error when an instance setter named
// foo= is declared in a class inheriting an instance method, field, or getter
// named foo, or an instance setter named foo=.

import "package:expect/expect.dart";
import "package:meta/meta.dart" show virtual;

class A {
  @virtual
  var foo = 42; // //# 00: ok
  get foo => 42; // //# 01: ok
  foo() => 42; // //# 02: ok
  set foo(value) {} // //# 03: ok
}

class B extends A {
  var foo_;
  set foo(value) {
    foo_ = value;
  }
}

main() {
  var b = new B();
  b.foo = 42;
  Expect.equals(42, b.foo_);
}
