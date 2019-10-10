// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subtyping for the `inout` variance modifier.

// SharedOptions=--enable-experiment=variance

class Invariant<inout T> {}

class A {
  Invariant<num> method1() {
    return new Invariant<num>();
  }

  void method2(Invariant<num> x) {}
}

class B extends A {
  @override
  Invariant<num> method1() {
    return new Invariant<num>();
  }

  @override
  void method2(Invariant<num> x) {}
}

main() {
  A a = new A();
  a.method2(new Invariant<num>());

  B b = new B();
  b.method2(new Invariant<num>());
}
