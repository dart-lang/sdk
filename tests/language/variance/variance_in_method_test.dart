// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests method signatures and return types for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

import "variance_helper.dart";

CovFunction<int> covFunction = () => 2;
ContraFunction<int> contraFunction = (int val) {};

class A<in T> {
  void method1(T x) {}
  void method2(CovFunction<T> x) {}
  ContraFunction<T> method3() {
    return (T val) {
      Expect.equals(2, val);
    };
  }

  void method4(CovFunction<CovFunction<T>> x) {}
  ContraFunction<CovFunction<T>> method5() {
    return (CovFunction<T> method) {
      Expect.type<CovFunction<T>>(method);
    };
  }
  CovFunction<ContraFunction<T>> method6() {
    return () {
      return (T x) {
        Expect.equals(2, x);
      };
    };
  }
  void method7(ContraFunction<ContraFunction<T>> x) {}

  void method8(Covariant<T> x) {}
  Contravariant<T>? method9() => null;
  void method10(Covariant<Covariant<T>> x) {}
  Contravariant<Covariant<T>>? method11() => null;
  void method12(Contravariant<Contravariant<T>> x) {}
  Covariant<Contravariant<T>>? method13() => null;

  void method14(covariant T x) {}
  void method15(covariant ContraFunction<T> x) {}
  void method16(covariant CovFunction<T> x) {}
  void method17(covariant Contravariant<T> x) {}
  void method18(covariant Covariant<T> x) {}

  void method19({T? x}) {}
  void method20({Covariant<T>? x}) {}
  void method21({CovFunction<T>? x}) {}
}

mixin BMixin<in T> {
  void method1(T x) {}
  void method2(CovFunction<T> x) {}
  ContraFunction<T> method3() {
    return (T val) {
      Expect.equals(2, val);
    };
  }

  void method4(CovFunction<CovFunction<T>> x) {}
  ContraFunction<CovFunction<T>> method5() {
    return (CovFunction<T> method) {
      Expect.type<CovFunction<T>>(method);
    };
  }
  CovFunction<ContraFunction<T>> method6() {
    return () {
      return (T x) {
        Expect.equals(2, x);
      };
    };
  }
  void method7(ContraFunction<ContraFunction<T>> x) {}

  void method8(Covariant<T> x) {}
  Contravariant<T>? method9() => null;
  void method10(Covariant<Covariant<T>> x) {}
  Contravariant<Covariant<T>>? method11() => null;
  void method12(Contravariant<Contravariant<T>> x) {}
  Covariant<Contravariant<T>>? method13() => null;

  void method14(covariant T x) {}
  void method15(covariant ContraFunction<T> x) {}
  void method16(covariant CovFunction<T> x) {}
  void method17(covariant Contravariant<T> x) {}
  void method18(covariant Covariant<T> x) {}

  void method19({T? x}) {}
  void method20({Covariant<T>? x}) {}
  void method21({CovFunction<T>? x}) {}
}

class B with BMixin<int> {}

class C<in T> {
  void method1(ContraFunction<A<T>> x) {}
  A<T> method2() {
    return A<T>();
  }
}

class D<T> {
  late T x;
  T? method() => null;
  void method2(T x) {}
  void method3(covariant T x) {}
}

class E<in T> extends D<void Function(T)> {
  @override
  void Function(T) method() => (T x) {};

  @override
  void method3(covariant void Function(T) x) {}
}

void testClass() {
  A<int> a = new A();

  a.method1(2);

  a.method2(covFunction);

  Expect.type<ContraFunction<int>>(a.method3());
  ContraFunction<int> method3Function = a.method3();
  method3Function(2);

  a.method4(() {
    return covFunction;
  });

  Expect.type<ContraFunction<CovFunction<int>>>(a.method5());
  ContraFunction<CovFunction<int>> method5Function = a.method5();
  method5Function(covFunction);

  Expect.type<CovFunction<ContraFunction<int>>>(a.method6());
  CovFunction<ContraFunction<int>> method6Function = a.method6();
  Expect.type<ContraFunction<int>>(method6Function());
  ContraFunction<int> method6NestedFunction = method6Function();
  method6NestedFunction(2);

  a.method7((ContraFunction<int> x) {});

  a.method8(Covariant<int>());
  Expect.isNull(a.method9());
  a.method10(Covariant<Covariant<int>>());
  Expect.isNull(a.method11());
  a.method12(Contravariant<Contravariant<int>>());
  Expect.isNull(a.method13());

  a.method14(3);
  a.method15(contraFunction);
  a.method16(covFunction);
  a.method17(Contravariant<int>());
  a.method18(Covariant<int>());

  a.method19();
  a.method20();
  a.method21();
}

void testMixin() {
  B b = new B();

  b.method1(2);

  b.method2(covFunction);

  Expect.type<ContraFunction<int>>(b.method3());
  ContraFunction<int> method3Return = b.method3();
  method3Return(2);

  b.method4(() {
    return covFunction;
  });

  Expect.type<ContraFunction<CovFunction<int>>>(b.method5());
  ContraFunction<CovFunction<int>> method5Return = b.method5();
  method5Return(covFunction);

  Expect.type<CovFunction<ContraFunction<int>>>(b.method6());
  CovFunction<ContraFunction<int>> method6Function = b.method6();
  Expect.type<ContraFunction<int>>(method6Function());
  ContraFunction<int> method6NestedFunction = method6Function();
  method6NestedFunction(2);

  b.method7((ContraFunction<int> x) {});

  b.method8(Covariant<int>());
  Expect.isNull(b.method9());
  b.method10(Covariant<Covariant<int>>());
  Expect.isNull(b.method11());
  b.method12(Contravariant<Contravariant<int>>());
  Expect.isNull(b.method13());

  b.method14(3);
  b.method15(contraFunction);
  b.method16(covFunction);
  b.method17(Contravariant<int>());
  b.method18(Covariant<int>());

  b.method19();
  b.method20();
  b.method21();
}

void testClassInMethods() {
  C<int> c = new C();

  c.method1((A<int> x) {});

  Expect.type<A<int>>(c.method2());
}

void testOverrideLegacyMethods() {
  E<int> e = new E();
  Expect.isTrue(e.method() is Function);
  e.method2(contraFunction);
  e.method3(contraFunction);
  e.x = contraFunction;

  D<Object> d = e;
  Expect.throws(() => d.x = "test");

  e = new E<Object>();
  Expect.throws(() => e.method2(contraFunction));
  Expect.throws(() => e.method3(contraFunction));
}

main() {
  testClass();
  testMixin();
  testClassInMethods();
  testOverrideLegacyMethods();
}
