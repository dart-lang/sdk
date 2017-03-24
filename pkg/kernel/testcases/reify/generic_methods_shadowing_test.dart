// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type parameters in generic methods can be shadowed.

library generic_methods_shadowing_test;

import "test_base.dart";

class X {}

class Y {}

bool foo<T, S>(T t, S s) {
  // The type parameter T of bar shadows the type parameter T of foo.
  bool bar<T>(T t) {
    return t is T && t is S;
  }

  return bar<S>(s);
}

main() {
  expectTrue(foo<X, Y>(new X(), new Y()));
}
