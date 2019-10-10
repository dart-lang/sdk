// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subtyping for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

class Contravariant<in T> {}

class A {
  Contravariant<num> method1() {
    return Contravariant<num>();
  }

  void method2(Contravariant<num> x) {}
}

class B extends A {
  @override
  Contravariant<Object> method1() {
    return new Contravariant<Object>();
  }

  @override
  void method2(Contravariant<int> x) {}
}

class C extends A {
  @override
  Contravariant<num> method1() {
    return new Contravariant<num>();
  }

  @override
  void method2(Contravariant<num> x) {}
}

main() {
  A a = new A();
  a.method2(new Contravariant<num>());
  a.method2(new Contravariant<Object>());

  B b = new B();
  b.method2(new Contravariant<int>());
  b.method2(new Contravariant<num>());

  C c = new C();
  c.method2(new Contravariant<num>());
  c.method2(new Contravariant<Object>());
}
