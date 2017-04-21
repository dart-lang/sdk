// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a generic closure is correctly constructed.

library generic_methods_closure_test;

import "test_base.dart";

class A {}

class I<T> {}

class B extends I<B> {}

void fun<T>(List<T> list) {
  var helper1 = <S>(List<S> list) {
    if (list.length > 0) {
      expectTrue(list[0] is S);
    }
    expectTrue(list is List<S>);
    expectTrue(list is List<T>);
  };

  void helper2<S>(List<S> list) {
    if (list.length > 0) {
      expectTrue(list[0] is S);
    }
    expectTrue(list is List<S>);
    expectTrue(list is List<T>);
  }

  helper1<T>(list);
  helper2<T>(list);
}

main() {
  List<B> list = <B>[new B()];
  fun<B>(list);
}
