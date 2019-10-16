// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subtyping for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

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
  a.method2(new Contravariant<Middle>());
  a.method2(new Contravariant<Upper>());

  B b = new B();
  b.method2(new Contravariant<Lower>());
  b.method2(new Contravariant<Middle>());

  C c = new C();
  c.method2(new Contravariant<Middle>());
  c.method2(new Contravariant<Upper>());

  D<Contravariant<Upper>> dUpper = new D<Contravariant<Upper>>();
  D<Contravariant<Middle>> dMiddle = new D<Contravariant<Middle>>();

  E e = new E();

  F f = new F();

  Iterable<Contravariant<Lower>> iterableLower = [new Contravariant<Lower>()];
  List<Contravariant<Middle>> listMiddle = [new Contravariant<Middle>()];
  iterableLower = listMiddle;

  testCall(listMiddle);
}
