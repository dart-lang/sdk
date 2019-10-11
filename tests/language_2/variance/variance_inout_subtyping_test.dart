// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subtyping for the `inout` variance modifier.

// SharedOptions=--enable-experiment=variance

class Invariant<inout T> {}

class Upper {}
class Middle extends Upper {}
class Lower extends Middle {}

class A {
  Invariant<Middle> method1() {
    return new Invariant<Middle>();
  }

  void method2(Invariant<Middle> x) {}
}

class B extends A {
  @override
  Invariant<Middle> method1() {
    return new Invariant<Middle>();
  }

  @override
  void method2(Invariant<Middle> x) {}
}

class C<out X extends Invariant<Middle>> {}

class D {
  C<Invariant<Middle>> method1() {
    return C<Invariant<Middle>>();
  }
}

void testCall(Iterable<Invariant<Middle>> x) {}

main() {
  A a = new A();
  a.method2(new Invariant<Middle>());

  B b = new B();
  b.method2(new Invariant<Middle>());

  C<Invariant<Middle>> c = new C<Invariant<Middle>>();

  D d = new D();

  Iterable<Invariant<Middle>> iterableMiddle = [new Invariant<Middle>()];
  List<Invariant<Middle>> listMiddle = [new Invariant<Middle>()];
  iterableMiddle = listMiddle;

  testCall(listMiddle);
}
