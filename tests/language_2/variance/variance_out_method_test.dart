// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests method signatures and return types for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

typedef Cov<T> = T Function();
typedef Contra<T> = void Function(T);

Cov<int> covFunction = () => 2;
Contra<int> contraFunction = (int val) {};

class Covariant<out T> {}
class Contravariant<in T> {}

class A<out T> {
  // TODO (kallentu): Come NNBD, change `T` to `T?`
  T method1() => null;
  void method2(Contra<T> x) {}
  Cov<T> method3() {
    return () => null;
  }

  void method4(Contra<Cov<T>> x) {}
  void method5(Cov<Contra<T>> x) {}
  Contra<Contra<T>> method6() {
    return (Contra<T> x) {
      Expect.type<Contra<T>>(x);
    };
  }

  Cov<Cov<T>> method7() {
    return () {
      return () => null;
    };
  }

  void method8(Contravariant<T> x) {}
  Covariant<T> method9() => null;
  void method10(Contravariant<Covariant<T>> x) {}
  Covariant<Covariant<T>> method11() => null;
  void method12(Covariant<Contravariant<T>> x) {}
  Contravariant<Contravariant<T>> method13() => null;

  void method14(covariant T x) {}
  void method15(covariant Contra<T> x) {}
  void method16(covariant Cov<T> x) {}
  void method17(covariant Contravariant<T> x) {}
  void method18(covariant Covariant<T> x) {}

  void method19({Contravariant<T> x}) {}
  void method20({Contra<T> x}) {}
}

mixin BMixin<out T> {
  // TODO (kallentu): Come NNBD, change `T` to `T?`
  T method1() => null;
  void method2(Contra<T> x) {}
  Cov<T> method3() {
    return () => null;
  }

  void method4(Contra<Cov<T>> x) {}
  void method5(Cov<Contra<T>> x) {}
  Contra<Contra<T>> method6() {
    return (Contra<T> x) {
      Expect.type<Contra<T>>(x);
    };
  }

  Cov<Cov<T>> method7() {
    return () {
      return () => null;
    };
  }

  void method8(Contravariant<T> x) {}
  Covariant<T> method9() => null;
  void method10(Contravariant<Covariant<T>> x) {}
  Covariant<Covariant<T>> method11() => null;
  void method12(Covariant<Contravariant<T>> x) {}
  Contravariant<Contravariant<T>> method13() => null;

  void method14(covariant T x) {}
  void method15(covariant Contra<T> x) {}
  void method16(covariant Cov<T> x) {}
  void method17(covariant Contravariant<T> x) {}
  void method18(covariant Covariant<T> x) {}

  void method19({Contravariant<T> x}) {}
  void method20({Contra<T> x}) {}
}

class B with BMixin<int> {}

class C<out T> {
  void method1(Contra<A<T>> x) {}
  A<T> method2() {
    return A<T>();
  }
}

class D<T> {
  T method() => null;
  void method2(T x) {}
  void method3(covariant T x) {}
}

class E<out T> extends D<T> {
  @override
  T method() => null;

  @override
  void method3(covariant T x) {}
}

void testClass() {
  A<int> a = new A();

  Expect.isNull(a.method1());

  a.method2(contraFunction);

  Expect.type<Cov<int>>(a.method3());
  Cov<int> method3Function = a.method3();
  Expect.isNull(method3Function());

  a.method4((Cov<int> x) {});

  a.method5(() {
    return contraFunction;
  });

  Expect.type<Contra<Contra<int>>>(a.method6());
  Contra<Contra<int>> method6Function = a.method6();
  method6Function(contraFunction);

  Expect.type<Cov<Cov<int>>>(a.method7());
  Cov<Cov<int>> method7Function = a.method7();
  Expect.type<Cov<int>>(method7Function());
  Cov<int> method7NestedFunction = method7Function();
  Expect.isNull(method7NestedFunction());

  a.method8(Contravariant<int>());
  Expect.isNull(a.method9());
  a.method10(Contravariant<Covariant<int>>());
  Expect.isNull(a.method11());
  a.method12(Covariant<Contravariant<int>>());
  Expect.isNull(a.method13());

  a.method14(3);
  a.method15(contraFunction);
  a.method16(covFunction);
  a.method17(Contravariant<int>());
  a.method18(Covariant<int>());

  a.method19();
  a.method20();
}

void testMixin() {
  B b = new B();

  Expect.isNull(b.method1());

  b.method2(contraFunction);

  Expect.type<Cov<int>>(b.method3());
  Cov<int> method3Function = b.method3();
  Expect.isNull(method3Function());

  b.method4((Cov<int> x) {});

  b.method5(() {
    return contraFunction;
  });

  Expect.type<Contra<Contra<int>>>(b.method6());
  Contra<Contra<int>> method6Function = b.method6();
  method6Function(contraFunction);

  Expect.type<Cov<Cov<int>>>(b.method7());
  Cov<Cov<int>> method7Function = b.method7();
  Expect.type<Cov<int>>(method7Function());
  Cov<int> method7NestedFunction = method7Function();
  Expect.isNull(method7NestedFunction());

  b.method8(Contravariant<int>());
  Expect.isNull(b.method9());
  b.method10(Contravariant<Covariant<int>>());
  Expect.isNull(b.method11());
  b.method12(Covariant<Contravariant<int>>());
  Expect.isNull(b.method13());

  b.method14(3);
  b.method15(contraFunction);
  b.method16(covFunction);
  b.method17(Contravariant<int>());
  b.method18(Covariant<int>());

  b.method19();
  b.method20();
}

void testClassInMethods() {
  C<int> c = new C();

  c.method1((A<int> x) {});

  Expect.type<A<int>>(c.method2());
}

void testOverrideLegacyMethods() {
  E<int> e = new E();
  Expect.isNull(e.method());
  e.method2(3);
  e.method3(3);

  D<Object> d = e;
  Expect.throws(() => d.method2("test"));
  Expect.throws(() => d.method3("test"));
}

main() {
  testClass();
  testMixin();
  testClassInMethods();
  testOverrideLegacyMethods();
}
