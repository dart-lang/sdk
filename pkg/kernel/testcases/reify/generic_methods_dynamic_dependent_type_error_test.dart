// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that if the type of a parameter of a generic method depends on type
// parameter, the type of the passed argument is checked at runtime if the
// receiver is dynamic, and an exception is thrown.

library generic_methods_dynamic_dependent_type_error_test;

import "test_base.dart";

class A {}

class B {}

class C {
  List<T> bar<T>(Iterable<T> t) => <T>[t.first];
}

main() {
  C c = new C();
  dynamic obj = c;

  expectThrows(() => obj.bar<A>(<B>[new B()]), (e) => e is TypeError);
}
