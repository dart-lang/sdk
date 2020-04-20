// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subtyping for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

class Covariant<out T> {}

class Upper {}
class Middle extends Upper {}
class Lower extends Middle {}

class A {
  Covariant<Middle> method1() {
    return new Covariant<Middle>();
  }

  void method2(Covariant<Middle> x) {}
}

class B extends A {
  @override
  Covariant<Lower> method1() {
    return new Covariant<Lower>();
  }

  @override
  void method2(Covariant<Upper> x) {}
}

class C extends A {
  @override
  Covariant<Middle> method1() {
    return new Covariant<Middle>();
  }

  @override
  void method2(Covariant<Middle> x) {}
}

class D<out T extends Covariant<Middle>> {}

class E {
  D<Covariant<Lower>> method1() {
    return D<Covariant<Lower>>();
  }
}

class F {
  D<Covariant<Middle>> method1() {
    return D<Covariant<Middle>>();
  }
}

void testCall(Iterable<Covariant<Middle>> x) {}

main() {
  A a = new A();
  Expect.type<Covariant<Middle>>(a.method1());
  Expect.type<Covariant<Upper>>(a.method1());
  Expect.notType<Covariant<Lower>>(a.method1());
  a.method2(new Covariant<Middle>());
  a.method2(new Covariant<Lower>());

  B b = new B();
  Expect.type<Covariant<Upper>>(b.method1());
  Expect.type<Covariant<Middle>>(b.method1());
  Expect.type<Covariant<Lower>>(b.method1());
  b.method2(new Covariant<Upper>());
  b.method2(new Covariant<Middle>());

  C c = new C();
  Expect.type<Covariant<Middle>>(c.method1());
  Expect.type<Covariant<Upper>>(c.method1());
  Expect.notType<Covariant<Lower>>(c.method1());
  c.method2(new Covariant<Middle>());
  c.method2(new Covariant<Lower>());

  D<Covariant<Lower>> dLower = new D<Covariant<Lower>>();
  D<Covariant<Middle>> dMiddle = new D<Covariant<Middle>>();

  E e = new E();
  Expect.type<D<Covariant<Lower>>>(e.method1());
  Expect.type<D<Covariant<Middle>>>(e.method1());

  F f = new F();
  Expect.type<D<Covariant<Middle>>>(f.method1());

  Iterable<Covariant<Middle>> iterableMiddle = [new Covariant<Middle>()];
  List<Covariant<Lower>> listLower = [new Covariant<Lower>()];
  iterableMiddle = listLower;

  testCall(listLower);

  Expect.subtype<Covariant<Lower>, Covariant<Middle>>();
  Expect.subtype<Covariant<Middle>, Covariant<Middle>>();
  Expect.notSubtype<Covariant<Upper>, Covariant<Middle>>();
}
