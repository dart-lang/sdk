// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that generic methods can be overloaded (a) with widened type bounds, and
// (b) using the bound as the type of the parameter in the overloaded method.

library generic_methods_overriding_test;

import "package:expect/expect.dart";

class X {}

class Y extends X {}

class Z extends Y {}

class C {
  String fun<T extends Y>(T t) => "C";
}

class D extends C {
  String fun<T extends X>(T t) => "D"; //# 01: compile-time error
  String fun<T extends Y>(T t) => "D"; //# 02: ok
}

class E extends C {
  String fun<T>(Y y) => "E"; //# 03: compile-time error
  String fun<T extends Y>(Y y) => "E"; //# 04: ok
}

class F extends C {
  String foobar(Z z) {
    return "FZ";
  }

  String fun<T extends Y>(T t) {
    if (t is Z) {
      return this.foobar(t as Z); //# 05: ok
      return this.foobar(t); //# 06: ok
    }
    return "FY";
  }
}

main() {
  Y y = new Y();
  Z z = new Z();

  C c = new C();
  D d = new D();
  E e = new E();
  F f = new F();

  Expect.equals(c.fun<Y>(y), "C");
  Expect.equals(d.fun<Y>(y), "D"); //# 02: continued
  Expect.equals(e.fun<Y>(y), "E"); //# 04: continued
  Expect.equals(f.fun<Y>(y), "FY"); //# 05: continued
  Expect.equals(f.fun<Z>(z), "FZ"); //# 05: continued
  Expect.equals(f.fun<Y>(y), "FY"); //# 06: continued
  Expect.equals(f.fun<Z>(z), "FZ"); //# 06: continued
}
