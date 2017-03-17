// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that F-bounded quantification works for generic methods.

library generic_methods_recursive_bound_test;

import "test_base.dart";

abstract class I<T> {
  bool fun(T x);
}

int foo<T extends I<T>>(List<T> a) {
  if (a.length > 1) {
    a[0].fun(a[1]);
  }
  return a.length;
}

class C implements I<C> {
  bool fun(C c) => true;
}

main() {
  expectTrue(foo<C>(<C>[new C(), new C()]) == 2);
}
