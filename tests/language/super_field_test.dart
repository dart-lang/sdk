// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing super field access.


class A {
  A() {
    city = "Bern";
  }
  String greeting() {
    return "Gruezi";
  }
  String city;
}


class B extends A {
  B() : super() {}
  String greeting() {
    return "Hola ".concat(super.greeting());
  }
}


class C extends B {
  C() : super() {}
  String greeting() {
    return "Servus ".concat(super.greeting());
  }
  String get city() {
    return "Basel ".concat(super.city);
  }
}


class SuperFieldTest {
  static testMain() {
    A a = new A();
    B b = new B();
    C c = new C();
    Expect.equals("Gruezi", a.greeting());
    Expect.equals("Hola Gruezi", b.greeting());
    Expect.equals("Servus Hola Gruezi", c.greeting());

    Expect.equals("Bern", a.city);
    Expect.equals("Bern", b.city);
    Expect.equals("Basel Bern", c.city);
    c.city = "Zurich";
    Expect.equals("Basel Zurich", c.city);
  }
}

main() {
  SuperFieldTest.testMain();
}
