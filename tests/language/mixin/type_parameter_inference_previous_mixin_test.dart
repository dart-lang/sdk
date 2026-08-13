// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:expect/static_type_helper.dart";

abstract class A<T> {
  // This is ok because type inference will ensure that in C, A and M are
  // instantiated with the same T.
  T f(T x) => x;
}

class B {}

mixin M1 implements A<B> {}

mixin M2<T> on A<T> {
  T f(T x) => x;
  T g(T x) => x;
  Type h() => T;
}

// Inferred as `class C extends Object with M1, M2<B>`
class C extends Object with M1, M2 {}

main() {
  C c = new C();

  // M is instantiated with B.
  A<B> asA = c; // Allowed.

  // So C.g has type (B) -> B.
  // Static type.
  Expect.equals(typeOf<B Function(B)>(), c.g.staticType);
  // Runtime type. Is covariant-by-generic, so actual argument type is Object?.
  Expect.equals(typeOf<B Function(Object?)>(), c.g.runtimeType);

  // And verify that the runtime system has the right type for the type
  // parameter
  Expect.equals(B, c.h());
}
