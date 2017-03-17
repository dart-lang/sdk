// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that generic methods can be overridden.

library generic_methods_overriding_test;

import "test_base.dart";

class X {}

class Y extends X {}

class C {
  String fun<T extends Y>(T t) => "C";
}

class D extends C {
  String fun<T extends Y>(T t) => "D";
}

main() {
  Y y = new Y();

  C c = new C();
  D d = new D();

  expectTrue(c.fun<Y>(y) == "C");
  expectTrue(d.fun<Y>(y) == "D");
}
