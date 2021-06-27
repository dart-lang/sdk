// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<X> {
  factory C() => new C.foo();
  C.foo() {}
  factory C.bar() = C;
}
class D<X> {
  D();
  factory D.foo() => new D();
  factory D.bar() = D;
}
typedef G<X> = X Function(X);
typedef A<X extends G<C<X>>> = C<X>;
typedef B<X extends G<D<X>>> = D<X>;

test() {
  A(); // Error.
  A.foo(); // Error.
  A.bar(); // Error.
  B(); // Error.
  B.foo(); // Error.
  B.bar(); // Error.
}

main() {}
