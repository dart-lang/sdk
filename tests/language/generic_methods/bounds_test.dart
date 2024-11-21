// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

// Test that a dynamic call to a generic function checks the type argument
// against its bound.

library generic_methods_bounds_test;

import "package:expect/expect.dart";

class A {}

class B {}

class C {
  void fun<T extends A>(T t) {}
}

main() {
  C c = new C();
  c.fun<B>(new B()); //# 01: compile-time error

  dynamic obj = new C();
  obj.fun<B>(new B()); //# 02: runtime error
}
