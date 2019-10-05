// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests method signatures and return types for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

typedef Cov<T> = T Function();
typedef Contra<T> = void Function(T);

class A<in T> {
  void method1(T x) {}
  void method2(Cov<T> x) {}
  Contra<T> method3() {
    return (T val) {
      Expect.equals(2, val);
    };
  }

  void method4(Cov<Cov<T>> x) {}
  Contra<Cov<T>> method5() {
    return (Cov<T> method) {
      Expect.type<Cov<T>>(method);
    };
  }
  Cov<Contra<T>> method6() {
    return () {
      return (T x) {
        Expect.equals(2, x);
      };
    };
  }
  void method7(Contra<Contra<T>> x) {}
}

mixin BMixin<in T> {
  void method1(T x) {}
  void method2(Cov<T> x) {}
  Contra<T> method3() {
    return (T val) {
      Expect.equals(2, val);
    };
  }

  void method4(Cov<Cov<T>> x) {}
  Contra<Cov<T>> method5() {
    return (Cov<T> method) {
      Expect.type<Cov<T>>(method);
    };
  }
  Cov<Contra<T>> method6() {
    return () {
      return (T x) {
        Expect.equals(2, x);
      };
    };
  }
  void method7(Contra<Contra<T>> x) {}
}

class B with BMixin<int> {}

class C<in T> {
  void method1(Contra<A<T>> x) {}
  A<T> method2() {
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

  a.method4(() {
    return () => 2;
  });

  Expect.type<Contra<Cov<int>>>(a.method5());
  Contra<Cov<int>> method5Function = a.method5();
  method5Function(() => 2);

  Expect.type<Cov<Contra<int>>>(a.method6());
  Cov<Contra<int>> method6Function = a.method6();
  Expect.type<Contra<int>>(method6Function());
  Contra<int> method6NestedFunction = method6Function();
  method6NestedFunction(2);

  a.method7((Contra<int> x) {});
}

void testMixin() {
  B b = new B();

  b.method1(2);

  b.method2(() => 2);

  Expect.type<Contra<int>>(b.method3());
  Contra<int> method3Return = b.method3();
  method3Return(2);

  b.method4(() {
    return () => 2;
  });

  Expect.type<Contra<Cov<int>>>(b.method5());
  Contra<Cov<int>> method5Return = b.method5();
  method5Return(() => 2);

  Expect.type<Cov<Contra<int>>>(b.method6());
  Cov<Contra<int>> method6Function = b.method6();
  Expect.type<Contra<int>>(method6Function());
  Contra<int> method6NestedFunction = method6Function();
  method6NestedFunction(2);

  b.method7((Contra<int> x) {});
}

void testClassInMethods() {
  C<int> c = new C();

  c.method1((A<int> x) {});

  Expect.type<A<int>>(c.method2());
}

main() {
  testClass();
  testMixin();
  testClassInMethods();
}
