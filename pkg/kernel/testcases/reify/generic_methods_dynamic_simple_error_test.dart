// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that if the type of a parameter of a generic method is a type parameter,
// the type of the passed argument is checked at runtime if the receiver is
// dynamic, and an exception is thrown.

library generic_methods_dynamic_simple_error_test;

import "test_base.dart";

class A {}

class B {}

class C {
  T foo<T>(T t) => t;
}

main() {
  B b = new B();
  C c = new C();
  dynamic obj = c;

  expectThrows(() => obj.foo<A>(b), (e) => e is TypeError);
}
