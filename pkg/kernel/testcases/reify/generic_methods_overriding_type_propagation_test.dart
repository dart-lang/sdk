// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that generic methods that have bounds on type parameters can be
// overridden, and that type propagation can be used in such methods.

library generic_methods_overriding_type_propagation_test;

import "test_base.dart";

class X {}

class Y extends X {}

class Z extends Y {}

class C {
  String fun<T extends Y>(T t) => "C";
}

class F extends C {
  String foobar(Z z) {
    return "FZ";
  }

  String fun<T extends Y>(T t) {
    if (t is Z) {
      return this.foobar(t as Z);
    }
    return "FY";
  }
}

main() {
  Y y = new Y();
  Z z = new Z();

  C c = new C();
  F f = new F();

  expectTrue(c.fun<Y>(y) == "C");

  expectTrue(f.fun<Y>(y) == "FY");
  expectTrue(f.fun<Z>(z) == "FZ");
}
