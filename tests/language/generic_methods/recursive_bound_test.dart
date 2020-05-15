// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that F-bounded quantification works for generic methods, and that types
// that are passed to generic methods in dynamic calls are checked for being
// recursively defined.

library generic_methods_recursive_bound_test;

import "package:expect/expect.dart";

abstract class I<T> {
  bool fun(T x);
}

void foo<T extends I<T>>(List<T> a) {
  if (a.length > 1) {
    a[0].fun(a[1]);
  }
}

class C implements I<C> {
  bool fun(C c) => true;
}

main() {
  foo<C>(<C>[new C(), new C()]); //# 01: ok

  dynamic bar = foo;
  List<int> list2 = <int>[4, 2];
  // The type int does not extend I<int>.
  foo<int>(list2); //# 02: compile-time error
  bar<int>(list2); //# 03: runtime error
}
