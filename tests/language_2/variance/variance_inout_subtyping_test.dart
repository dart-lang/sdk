// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subtyping for the `inout` variance modifier.

// SharedOptions=--enable-experiment=variance

import 'dart:async';

import "package:expect/expect.dart";

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

class E {
  Invariant<dynamic> method1() {
    return new Invariant<dynamic>();
  }

  void method2(Invariant<Object> x) {}
}

class F extends E {
  @override
  Invariant<Object> method1() {
    return new Invariant<Object>();
  }

  @override
  void method2(Invariant<dynamic> x) {}
}

class G {
  Invariant<dynamic> method1() {
    return new Invariant<dynamic>();
  }

  void method2(Invariant<FutureOr<dynamic>> x) {}
}

class H extends G {
  @override
  Invariant<FutureOr<dynamic>> method1() {
    return new Invariant<FutureOr<dynamic>>();
  }

  @override
  void method2(Invariant<dynamic> x) {}
}

class I {
  Invariant<FutureOr<Null>> method1() {
    return new Invariant<FutureOr<Null>>();
  }

  void method2(Invariant<Future<Null>> x) {}
}

class J extends I {
  @override
  Invariant<Future<Null>> method1() {
    return new Invariant<Future<Null>>();
  }

  @override
  void method2(Invariant<FutureOr<Null>> x) {}
}

void testCall(Iterable<Invariant<Middle>> x) {}

main() {
  A a = new A();
  Expect.type<Invariant<Middle>>(a.method1());
  Expect.notType<Invariant<Upper>>(a.method1());
  Expect.notType<Invariant<Lower>>(a.method1());
  a.method2(new Invariant<Middle>());

  B b = new B();
  Expect.type<Invariant<Middle>>(b.method1());
  Expect.notType<Invariant<Upper>>(b.method1());
  Expect.notType<Invariant<Lower>>(b.method1());
  b.method2(new Invariant<Middle>());

  C<Invariant<Middle>> c = new C<Invariant<Middle>>();

  D d = new D();
  Expect.type<C<Invariant<Middle>>>(d.method1());

  E e = new E();
  Expect.type<Invariant<dynamic>>(e.method1());
  e.method2(new Invariant<Object>());

  // Invariant<dynamic> <:> Invariant<Object>
  F f = new F();
  Expect.type<Invariant<Object>>(f.method1());
  Expect.type<Invariant<dynamic>>(f.method1());
  f.method2(new Invariant<Object>());
  f.method2(new Invariant<dynamic>());

  G g = new G();
  Expect.type<Invariant<dynamic>>(g.method1());
  g.method2(new Invariant<FutureOr<dynamic>>());

  // Invariant<FutureOr<dynamic>> <:> Invariant<dynamic>
  H h = new H();
  Expect.type<Invariant<FutureOr<dynamic>>>(h.method1());
  Expect.type<Invariant<dynamic>>(h.method1());
  h.method2(new Invariant<FutureOr<dynamic>>());
  h.method2(new Invariant<dynamic>());

  I i = new I();
  Expect.type<Invariant<FutureOr<Null>>>(i.method1());
  i.method2(new Invariant<Future<Null>>());

  // Invariant<FutureOr<Null>> <:> Invariant<Future<Null>>
  J j = new J();
  Expect.type<Invariant<FutureOr<Null>>>(j.method1());
  Expect.type<Invariant<Future<Null>>>(j.method1());
  j.method2(new Invariant<FutureOr<Null>>());
  j.method2(new Invariant<Future<Null>>());

  Iterable<Invariant<Middle>> iterableMiddle = [new Invariant<Middle>()];
  List<Invariant<Middle>> listMiddle = [new Invariant<Middle>()];
  iterableMiddle = listMiddle;

  testCall(listMiddle);

  Expect.subtype<Invariant<Middle>, Invariant<Middle>>();
  Expect.notSubtype<Invariant<Lower>, Invariant<Middle>>();
  Expect.notSubtype<Invariant<Upper>, Invariant<Middle>>();

  Expect.subtype<Invariant<dynamic>, Invariant<Object>>();
  Expect.subtype<Invariant<Object>, Invariant<dynamic>>();

  Expect.subtype<Invariant<FutureOr<dynamic>>, Invariant<dynamic>>();
  Expect.subtype<Invariant<dynamic>, Invariant<FutureOr<dynamic>>>();

  Expect.subtype<Invariant<FutureOr<Null>>, Invariant<Future<Null>>>();
  Expect.subtype<Invariant<Future<Null>>, Invariant<FutureOr<Null>>>();
}
