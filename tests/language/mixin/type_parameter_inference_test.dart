// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

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

class M2<T> {
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

  // M1 is instantiated with B, so C.g has type (B) -> B.
  B Function(B) x = c.g; //# 02: ok
  B Function(B) x = d.g; //# 03: ok
  Null Function(Null) x = c.g; //# 04: compile-time error
  Null Function(Null) x = d.g; //# 05: compile-time error
  Object Function(Object) x = c.g; //# 06: compile-time error
  Object Function(Object) x = d.g; //# 07: compile-time error

  // And verify that the runtime system has the right type for the type
  // parameter
  Expect.equals(c.h(), B); //# 08: ok
  Expect.equals(c.h(), B); //# 09: ok

  // M2 is instantiated with dynamic, so E.g has type (dynamic) -> dynamic.
  dynamic Function(dynamic) x = e.g; //# 10: ok
  B Function(B) x = e.g; //# 11: compile-time error

  // And verify that the runtime system has the right type for the type
  // parameter
  Expect.equals(e.h(), dynamic); //# 12: ok

  // M2 is instantiated with B, so F.g has type (B) -> B.
  B Function(B) x = f.g; //# 13: ok
  Null Function(Null) x = f.g; //# 14: compile-time error
  Object Function(Object) x = f.g; //# 15: compile-time error

  // And verify that the runtime system has the right type for the type
  // parameter
  Expect.equals(f.h(), B); //# 16: ok
}
