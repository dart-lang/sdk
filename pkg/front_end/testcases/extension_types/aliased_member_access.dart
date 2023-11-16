// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef A = B;

extension type B(int i) {
  B.named(this.i);
  static B method(int i) => B(i);
}

typedef C<X extends num> = D<X>;

extension type D<Y>(Y i) {
  D.named(this.i);
  static D<Y> method<Y>(Y i) => D<Y>(i);
}

typedef E<X extends num> = F<X>;

class F<Z> {
  F(Z i);
  F.named(Z i);

  static F<Z> method<Z>(Z i) => F<Z>(i);
}

method() {
  A.new(0); // Ok
  A.named(1); // Ok
  A.method(2); // Ok

  B.new(0); // Ok
  B.named(1); // Ok
  B.method(2); // Ok

  C.new(0); // Ok
  C.named(1); // Ok
  C.method(2); // Ok

  D.new(0); // Ok
  D.named(1); // Ok
  D.method(2); // Ok

  E.new(0); // Ok
  E.named(1); // Ok
  E.method(2); // Ok

  F.new(0); // Ok
  F.named(1); // Ok
  F.method(2); // Ok

  new A(0); // Ok
  new A.named(1); // Ok
  new A.method(2); // Error

  new B.new(0); // Ok
  new B.named(1); // Ok
  new B.method(2); // Error

  new C(0); // Ok
  new C.named(1); // Ok
  new C.method(2); // Error

  new D.new(0); // Ok
  new D.named(1); // Ok
  new D.method(2); // Error

  new E(0); // Ok
  new E.named(1); // Ok
  new E.method(2); // Error

  new F(0); // Ok
  new F.named(1); // Ok
  new F.method(2); // Error
}