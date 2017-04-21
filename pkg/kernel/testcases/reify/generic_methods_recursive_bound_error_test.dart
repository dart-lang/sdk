// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that F-bounded quantification works for generic methods, and that types
// that are passed to generic methods in dynamic calls are checked for being
// recursively defined. An exception should be thrown if the type doesn't meet
// the expectation.

library generic_methods_recursive_bound_error_test;

import "test_base.dart";

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
  dynamic bar = foo;
  List<int> list = <int>[4, 2];
  // The type int does not extend I<int>.
  expectThrows(() => bar<int>(list), (e) => e is TypeError);
}
