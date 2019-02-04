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

abstract class M1 implements A<B> {}

mixin M2<T> on A<T> {
  T f(T x) => x;
  T g(T x) => x;
  Type h() => T;
}

// Inferred as `class C extends Object with M1, M2<B>`
class C extends Object with M1, M2 {}

main() {
  C c = new C();

  // M is instantiated with B, so C.g has type (B) -> B.
  B Function(B) x = c.g; //# 02: ok
  Null Function(Null) x = c.g; //# 03: compile-time error
  Object Function(Object) x = c.g; //# 04: compile-time error

  // And verify that the runtime system has the right type for the type
  // parameter
  Expect.equals(c.h(), B); //# 05: ok
}
