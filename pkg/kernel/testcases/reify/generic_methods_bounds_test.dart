// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a dynamic call to a generic function checks the type argument
// against its bound.

library generic_methods_bounds_test;

import "test_base.dart";

class A {}

class B {}

class C {
  void fun<T extends A>(T t) {}
}

main() {
  dynamic obj = new C();
  expectThrows(() => obj.fun<B>(new B()), (e) => e is TypeError);
}
