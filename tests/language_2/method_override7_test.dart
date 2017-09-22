// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we report a compile-time error when a static function conflicts
// with an inherited instance member of the same name.

import "package:expect/expect.dart";

class A {
  var foo = 42; // //# 00: compile-time error
  get foo => 42; // //# 01: compile-time error
  foo() => 42; // //# 02: compile-time error
  set foo(value) { } // //# 03: compile-time error
}

class B extends A {
  static foo() => 42;
}

main() {
  Expect.equals(42, B.foo());
}
