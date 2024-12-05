// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

class A1<X extends A1<X, Y>, Y extends A2<X, Y>> {}

class A2<X extends A1<X, Y>, Y extends A2<X, Y>> {}

class B extends A1<B, B> implements A2<B, B> {}

class C1 extends B {}

class C2 extends B {}

class Pair<X, Y> {}

Pair<X, Y> f<X extends A1<X, Y>, Y extends A2<X, Y>>(X x, Y y) =>
    new Pair<X, Y>();

void main() {
  f<B, B>(C1(), C2()); // Ok.
  f(C1(), C2()); // Error.
//^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'C1' doesn't conform to the bound 'A1<X, Y>' of the type variable 'X' on 'f'.
// [cfe] Inferred type argument 'C2' doesn't conform to the bound 'A2<X, Y>' of the type variable 'Y' on 'f'.
}
