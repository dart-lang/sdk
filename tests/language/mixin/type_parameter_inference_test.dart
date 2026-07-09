// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:expect/static_type_helper.dart";

abstract class A<T> {
  // This is ok because type inference will ensure that in C, A and M are
  // instantiated with the same T.
  T f(T x) => x; //# 01: ok
}

class B {}

mixin M1<T> on A<T> {
  T f(T x) => x;
  T g(T x) => x;
  Type h() => T;
}

mixin class M2<T> {
  T g(T x) => x;
  Type h() => T;
}

// Inferred as `class C extends A<B> with M1<B>`
class C extends A<B> with M1 {}

// Inferred as `class D = A<B> with M1<B>`
class D = A<B> with M1;

// Inferred as `class E extends Object with M2<dynamic>`
class E extends Object with M2 {}

// Ok because a type parameter is supplied
class F extends Object with M2<B> {}

main() {
  C c = new C();
  D d = new D();
  E e = new E();
  F f = new F();

  // M1 is instantiated with B, so C.g has static type (B) -> B.
  Expect.equals(typeOf<B Function(B)>(), c.g.staticType);
  // Is covariant-by-generics, so runtime parameter type is Object?.
  Expect.equals(typeOf<B Function(Object?)>(), c.g.runtimeType);
  // And verify that the runtime system has the right type for the type
  // parameter
  Expect.equals(B, c.h());

  Expect.equals(typeOf<B Function(B)>(), d.g.staticType);
  Expect.equals(typeOf<B Function(Object?)>(), d.g.runtimeType);
  Expect.equals(B, d.h());

  // M2 is instantiated with dynamic, E.g has static type (dynamic) -> dynamic.
  Expect.equals(typeOf<dynamic Function(dynamic)>(), e.g.staticType);
  Expect.equals(typeOf<dynamic Function(Object?)>(), e.g.runtimeType);
  Expect.equals(dynamic, e.h());

  // M2 is instantiated with B, so F.g has type (B) -> B.
  Expect.equals(typeOf<B Function(B)>(), f.g.staticType);
  Expect.equals(typeOf<B Function(Object?)>(), f.g.runtimeType);
  Expect.equals(B, f.h());
}
