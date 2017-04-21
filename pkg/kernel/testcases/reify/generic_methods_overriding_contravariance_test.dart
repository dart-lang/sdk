// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that generic methods can be overridden using the bound of a type
// variable as the type of the parameter in the overloaded method.

library generic_methods_overriding_contravariance_test;

import "test_base.dart";

class X {}

class Y extends X {}

class Z extends Y {}

class C {
  String fun<T extends Y>(T t) => "C";
}

class E extends C {
  String fun<T extends Y>(Y y) => "E";
}

main() {
  Y y = new Y();

  C c = new C();
  E e = new E();

  expectTrue(c.fun<Y>(y) == "C");
  expectTrue(e.fun<Y>(y) == "E");
}
