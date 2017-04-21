// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we report a compile-time error when an instance getter conflicts
// with an inherited instance method of the same name.

import "package:expect/expect.dart";

class A {
  var foo = 42; // //# 00: ok
  get foo => 42; // //# 01: ok
  foo() => 42; // //# 02: compile-time error
  set foo(value) { } // //# 03: ok
}

class B extends A {
  get foo => 42;
}

main() {
  Expect.equals(42, new B().foo);
}
