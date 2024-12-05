// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends A<X>> {}
class B extends A<B> {}
class C extends B {}

void f<X extends A<X>>(X x) {}

void main() {
  f<B>(B());
  f(B()); // Inferred type argument: B.

  f<B>(C());
  f(C()); // Inferred type argument: B.
}
