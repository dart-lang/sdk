// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subtyping for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

class Covariant<out T> {}

class A {
  Covariant<num> method1() {
    return new Covariant<num>();
  }

  void method2(Covariant<num> x) {}
}

class B extends A {
  @override
  Covariant<int> method1() {
    return new Covariant<int>();
  }

  @override
  void method2(Covariant<Object> x) {}
}

class C extends A {
  @override
  Covariant<num> method1() {
    return new Covariant<num>();
  }

  @override
  void method2(Covariant<num> x) {}
}

main() {
  A a = new A();
  a.method2(new Covariant<num>());
  a.method2(new Covariant<int>());

  B b = new B();
  b.method2(new Covariant<Object>());
  b.method2(new Covariant<num>());

  C c = new C();
  c.method2(new Covariant<num>());
  c.method2(new Covariant<int>());
}
