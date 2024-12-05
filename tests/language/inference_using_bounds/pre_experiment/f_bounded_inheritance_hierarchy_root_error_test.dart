// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

class A<X extends A<X>> {}

class B extends A<B> {}

class C extends B {}

X f<X extends A<X>>(X x) => x;

void main() {
  f(B()); // Ok.
  f(C()); // Error.
//^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'C' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'f'.
  f<B>(C()); // Ok.
}
