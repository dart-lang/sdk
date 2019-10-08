// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests method signatures and return types for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

typedef Cov<T> = T Function();
typedef Contra<T> = void Function(T);

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
}

class B with BMixin<int> {}

class C<out T> {
  void method1(Contra<A<T>> x) {}
  A<T> method2() {
    return A<T>();
  }
}

void testClass() {
  A<int> a = new A();

  Expect.isNull(a.method1());

  a.method2((int x) {
    Expect.equals(2, x);
  });

  Expect.type<Cov<int>>(a.method3());
  Cov<int> method3Function = a.method3();
  Expect.isNull(method3Function());

  a.method4((Cov<int> x) {});

  a.method5(() {
    return (int x) {};
  });

  Expect.type<Contra<Contra<int>>>(a.method6());
  Contra<Contra<int>> method6Function = a.method6();
  method6Function((int x) {});

  Expect.type<Cov<Cov<int>>>(a.method7());
  Cov<Cov<int>> method7Function = a.method7();
  Expect.type<Cov<int>>(method7Function());
  Cov<int> method7NestedFunction = method7Function();
  Expect.isNull(method7NestedFunction());
}

void testMixin() {
  B b = new B();

  Expect.isNull(b.method1());

  b.method2((int x) {
    Expect.equals(2, x);
  });

  Expect.type<Cov<int>>(b.method3());
  Cov<int> method3Function = b.method3();
  Expect.isNull(method3Function());

  b.method4((Cov<int> x) {});

  b.method5(() {
    return (int x) {};
  });

  Expect.type<Contra<Contra<int>>>(b.method6());
  Contra<Contra<int>> method6Function = b.method6();
  method6Function((int x) {});

  Expect.type<Cov<Cov<int>>>(b.method7());
  Cov<Cov<int>> method7Function = b.method7();
  Expect.type<Cov<int>>(method7Function());
  Cov<int> method7NestedFunction = method7Function();
  Expect.isNull(method7NestedFunction());
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
