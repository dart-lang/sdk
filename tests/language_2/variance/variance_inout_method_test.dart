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

class Covariant<out T> {}
class Contravariant<in T> {}
class Invariant<inout T> {}

class A<inout T> {
  void method1(T x) {}
  void method2(Cov<T> x) {}
  Contra<T> method3() {
    return (T val) {
      Expect.equals(2, val);
    };
  }

  T method4() => null;
  void method5(Contra<T> x) {}
  Cov<T> method6() {
    return () => null;
  }

  T method7(T x) => x;
  Contra<T> method8(Contra<T> x) => x;
  Cov<T> method9(Cov<T> x) => x;

  T method10<S extends T>(S x) => x;

  void method11(Covariant<T> x) {}
  Covariant<T> method12() => null;
  void method13(Contravariant<T> x) {}
  Contravariant<T> method14() => null;
  void method15(Invariant<T> x) {}
  Invariant<T> method16() => null;

  void method17(covariant T x) {}
  void method18(covariant Contra<T> x) {}
  void method19(covariant Cov<T> x) {}
  void method20(covariant Contravariant<T> x) {}
  void method21(covariant Covariant<T> x) {}

  void method22<S extends Contravariant<T>>() {}
  void method23<S extends Covariant<T>>() {}
  void method24<S extends Contra<T>>() {}
  void method25<S extends Cov<T>>() {}

  void method26({Contra<T> a, Cov<T> b, T c}) {}
  void method27({Contravariant<T> a, Covariant<T> b}) {}
}

mixin BMixin<inout T> {
  void method1(T x) {}
  void method2(Cov<T> x) {}
  Contra<T> method3() {
    return (T val) {
      Expect.equals(2, val);
    };
  }

  T method4() => null;
  void method5(Contra<T> x) {}
  Cov<T> method6() {
    return () => null;
  }

  T method7(T x) => x;
  Contra<T> method8(Contra<T> x) => x;
  Cov<T> method9(Cov<T> x) => x;

  T method10<S extends T>(S x) => x;

  void method11(Covariant<T> x) {}
  Covariant<T> method12() => null;
  void method13(Contravariant<T> x) {}
  Contravariant<T> method14() => null;
  void method15(Invariant<T> x) {}
  Invariant<T> method16() => null;

  void method17(covariant T x) {}
  void method18(covariant Contra<T> x) {}
  void method19(covariant Cov<T> x) {}
  void method20(covariant Contravariant<T> x) {}
  void method21(covariant Covariant<T> x) {}

  void method22<S extends Contravariant<T>>() {}
  void method23<S extends Covariant<T>>() {}
  void method24<S extends Contra<T>>() {}
  void method25<S extends Cov<T>>() {}

  void method26({Contra<T> a, Cov<T> b, T c}) {}
  void method27({Contravariant<T> a, Covariant<T> b}) {}
}

class B with BMixin<num> {}

class C<inout T> {
  void method1(Contra<A<T>> x) {}
  void method2(Cov<A<T>> x) {}
  A<T> method3() {
    return A<T>();
  }
}

class D<T> {
  T method() => null;
  void method2(T x) {}
  void method3(covariant T x) {}
}

class E<inout T> extends D<T> {
  @override
  T method() => null;

  @override
  void method2(T x) {}

  @override
  void method3(covariant T x) {}
}

abstract class F<T> {
  int method(T x);
}

class G<inout T> {
  final void Function(T) f;
  G(this.f);
  int method(T x) {
    f(x);
  }
}

class H<inout T> extends G<T> implements F<T> {
  H(void Function(T) f) : super(f);
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

  a.method11(Covariant<int>());
  Expect.isNull(a.method12());
  a.method13(Contravariant<int>());
  Expect.isNull(a.method14());
  a.method15(Invariant<int>());
  Expect.isNull(a.method16());

  a.method17(3);
  a.method18(contraFunction);
  a.method19(covFunction);
  a.method20(Contravariant<int>());
  a.method21(Covariant<int>());

  a.method22<Contravariant<int>>();
  a.method23<Covariant<int>>();
  a.method24<Contra<int>>();
  a.method25<Cov<int>>();

  a.method26();
  a.method27();
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

  b.method11(Covariant<num>());
  Expect.isNull(b.method12());
  b.method13(Contravariant<num>());
  Expect.isNull(b.method14());
  b.method15(Invariant<num>());
  Expect.isNull(b.method16());

  b.method17(3);
  b.method18(contraFunctionNum);
  b.method19(covFunctionNum);
  b.method20(Contravariant<num>());
  b.method21(Covariant<num>());

  b.method22<Contravariant<num>>();
  b.method23<Covariant<num>>();
  b.method24<Contra<num>>();
  b.method25<Cov<num>>();

  b.method26();
  b.method27();
}

void testClassInMethods() {
  C<int> c = new C();

  c.method1((A<int> x) {});
  c.method2(() => null);

  Expect.type<A<int>>(c.method3());
}

void testOverrideLegacyMethods() {
  E<int> e = new E();
  Expect.isNull(e.method());
  e.method2(3);
  e.method3(3);

  D<Object> d = e;
  Expect.throws(() => d.method2("test"));
  Expect.throws(() => d.method3("test"));

  F<Object> f = new H<String>((String s) {});
  Expect.throws(() => f.method(3));

  // Tests reified type is the type expected for F and not G.
  Expect.type<int Function(Object)>(f.method);
  Expect.type<int Function(Object)>(new H<String>((String s){}).method);
}

main() {
  testClass();
  testMixin();
  testClassInMethods();
  testOverrideLegacyMethods();
}
