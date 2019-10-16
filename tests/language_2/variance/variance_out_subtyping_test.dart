// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subtyping for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

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
  a.method2(new Covariant<Middle>());
  a.method2(new Covariant<Lower>());

  B b = new B();
  b.method2(new Covariant<Upper>());
  b.method2(new Covariant<Middle>());

  C c = new C();
  c.method2(new Covariant<Middle>());
  c.method2(new Covariant<Lower>());

  D<Covariant<Lower>> dLower = new D<Covariant<Lower>>();
  D<Covariant<Middle>> dMiddle = new D<Covariant<Middle>>();

  E e = new E();

  F f = new F();

  Iterable<Covariant<Middle>> iterableMiddle = [new Covariant<Middle>()];
  List<Covariant<Lower>> listLower = [new Covariant<Lower>()];
  iterableMiddle = listLower;

  testCall(listLower);
}
