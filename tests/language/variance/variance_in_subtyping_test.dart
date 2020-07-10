// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subtyping for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

class Contravariant<in T> {}

class Upper {}
class Middle extends Upper {}
class Lower extends Middle {}

class A {
  Contravariant<Middle> method1() {
    return Contravariant<Middle>();
  }

  void method2(Contravariant<Middle> x) {}
}

class B extends A {
  @override
  Contravariant<Upper> method1() {
    return new Contravariant<Upper>();
  }

  @override
  void method2(Contravariant<Lower> x) {}
}

class C extends A {
  @override
  Contravariant<Middle> method1() {
    return new Contravariant<Middle>();
  }

  @override
  void method2(Contravariant<Middle> x) {}
}

class D<out T extends Contravariant<Middle>> {}

class E {
  D<Contravariant<Upper>> method1() {
    return D<Contravariant<Upper>>();
  }
}

class F {
  D<Contravariant<Middle>> method1() {
    return D<Contravariant<Middle>>();
  }
}

void testCall(Iterable<Contravariant<Lower>> x) {}

main() {
  A a = new A();
  Expect.type<Contravariant<Middle>>(a.method1());
  Expect.type<Contravariant<Lower>>(a.method1());
  Expect.notType<Contravariant<Upper>>(a.method1());
  a.method2(new Contravariant<Middle>());
  a.method2(new Contravariant<Upper>());

  B b = new B();
  Expect.type<Contravariant<Upper>>(b.method1());
  Expect.type<Contravariant<Middle>>(b.method1());
  Expect.type<Contravariant<Lower>>(b.method1());
  b.method2(new Contravariant<Lower>());
  b.method2(new Contravariant<Middle>());

  C c = new C();
  Expect.type<Contravariant<Middle>>(c.method1());
  Expect.type<Contravariant<Lower>>(c.method1());
  Expect.notType<Contravariant<Upper>>(c.method1());
  c.method2(new Contravariant<Middle>());
  c.method2(new Contravariant<Upper>());

  D<Contravariant<Upper>> dUpper = new D<Contravariant<Upper>>();
  D<Contravariant<Middle>> dMiddle = new D<Contravariant<Middle>>();

  E e = new E();
  Expect.type<D<Contravariant<Upper>>>(e.method1());
  Expect.type<D<Contravariant<Middle>>>(e.method1());

  F f = new F();
  Expect.type<D<Contravariant<Middle>>>(e.method1());

  Iterable<Contravariant<Lower>> iterableLower = [new Contravariant<Lower>()];
  List<Contravariant<Middle>> listMiddle = [new Contravariant<Middle>()];
  iterableLower = listMiddle;

  testCall(listMiddle);

  Expect.subtype<Contravariant<Upper>, Contravariant<Middle>>();
  Expect.subtype<Contravariant<Middle>, Contravariant<Middle>>();
  Expect.notSubtype<Contravariant<Lower>, Contravariant<Middle>>();
}
