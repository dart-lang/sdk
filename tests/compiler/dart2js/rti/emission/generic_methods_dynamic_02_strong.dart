// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on language/generic_methods_dynamic_test/02

library generic_methods_dynamic_test;

/*class: A:checkedInstance,checks=[],typeArgument*/
class A {}

/*class: B:checks=[],instance*/
class B {}

/*class: C:*/
class C {
  T foo<T>(T t) => t;
  List<T> bar<T>(Iterable<T> t) => <T>[t.first];
}

main() {
  B b = new B();
  C c = new C();
  dynamic obj = c;
  obj.foo<A>(b);
}
