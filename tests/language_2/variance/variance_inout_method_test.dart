// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests method signatures and return types for the `inout` variance modifier.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

typedef Cov<T> = T Function();
typedef Contra<T> = void Function(T);
Cov<int> covFunction = () => 2;
Contra<int> contraFunction = (int val) {};
Cov<num> covFunctionNum = () => 2;
Contra<num> contraFunctionNum = (num val) {};

class A<inout T> {
  // Contravariant positions
  void method1(T x) {}
  void method2(Cov<T> x) {}
  Contra<T> method3() {
    return (T val) {
      Expect.equals(2, val);
    };
  }

  // Covariant positions
  T method4() => null;
  void method5(Contra<T> x) {}
  Cov<T> method6() {
    return () => null;
  }

  // Invariant member signatures
  T method7(T x) => x;
  Contra<T> method8(Contra<T> x) => x;
  Cov<T> method9(Cov<T> x) => x;

  T method10<S extends T>(S x) => x;
}

mixin BMixin<inout T> {
  // Contravariant positions
  void method1(T x) {}
  void method2(Cov<T> x) {}
  Contra<T> method3() {
    return (T val) {
      Expect.equals(2, val);
    };
  }

  // Covariant positions
  T method4() => null;
  void method5(Contra<T> x) {}
  Cov<T> method6() {
    return () => null;
  }

  // Invariant member signatures
  T method7(T x) => x;
  Contra<T> method8(Contra<T> x) => x;
  Cov<T> method9(Cov<T> x) => x;

  T method10<S extends T>(S x) => x;
}

class B with BMixin<num> {}

class C<inout T> {
  void method1(Contra<A<T>> x) {}
  void method2(Cov<A<T>> x) {}
  A<T> method3() {
    return A<T>();
  }
}

void testClass() {
  A<int> a = new A();

  a.method1(2);

  a.method2(() => 2);

  Expect.type<Contra<int>>(a.method3());
  Contra<int> method3Function = a.method3();
  method3Function(2);

  Expect.isNull(a.method4());

  a.method5((int val) {});

  Expect.type<Cov<int>>(a.method6());
  Cov<int> method6Function = a.method6();
  Expect.isNull(method6Function());

  Expect.equals(3, a.method7(3));

  Expect.type<Contra<int>>(a.method8(contraFunction));
  Expect.equals(contraFunction, a.method8(contraFunction));

  Expect.type<Cov<int>>(a.method9(covFunction));
  Expect.equals(covFunction, a.method9(covFunction));

  A<num> aa = new A();
  Expect.type<num>(aa.method10(3));
}

void testMixin() {
  B b = new B();

  b.method1(2);

  b.method2(() => 2);

  Expect.type<Contra<num>>(b.method3());
  Contra<num> method3Function = b.method3();
  method3Function(2);

  Expect.isNull(b.method4());

  b.method5((num val) {});

  Expect.type<Cov<num>>(b.method6());
  Cov<num> method6Function = b.method6();
  Expect.isNull(method6Function());

  Expect.equals(3, b.method7(3));

  Expect.type<Contra<num>>(b.method8(contraFunctionNum));
  Expect.equals(contraFunctionNum, b.method8(contraFunctionNum));

  Expect.type<Cov<num>>(b.method9(covFunctionNum));
  Expect.equals(covFunctionNum, b.method9(covFunctionNum));

  Expect.type<num>(b.method10(3));
}

void testClassInMethods() {
  C<int> c = new C();

  c.method1((A<int> x) {});
  c.method2(() => null);

  Expect.type<A<int>>(c.method3());
}

main() {
  testClass();
  testMixin();
  testClassInMethods();
}
