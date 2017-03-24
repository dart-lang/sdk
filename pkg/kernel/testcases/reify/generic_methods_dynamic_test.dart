// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that if the type of a parameter of a generic method depends on a type
// parameter, the type of the passed argument is checked at runtime if the
// receiver is dynamic. The checks should pass if the variables are declared
// correctly.

library generic_methods_dynamic_test;

import "test_base.dart";

class A {}

class B {}

class C {
  T foo<T>(T t) => t;
  List<T> bar<T>(Iterable<T> t) => <T>[t.first];
}

main() {
  B b = new B();
  C c = new C();
  dynamic obj = c;

  expectTrue(c.foo<B>(b) == b);
  expectTrue(obj.foo<B>(b) == b);

  dynamic x = c.bar<B>(<B>[new B()]);
  expectTrue(x is List<B>);
  expectTrue(x.length == 1);

  dynamic y = obj.bar<B>(<B>[new B()]);
  expectTrue(y is List<B>);
  expectTrue(y.length == 1);
}
