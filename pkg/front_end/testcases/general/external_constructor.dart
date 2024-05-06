// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {}

class B {
  final A a;

  external B(A a); // Ok
}

class C {
  final A a1;
  final A a2;

  external C(); // Ok
  C.named(this.a1, this.a2); // Ok
}

class D {
  final A a1;
  final A a2;

  external D(); // Ok
  D.named(this.a1); // Error
}

class E {
  final A a1;
  final A a2;

  E(this.a2); // Error
  external E.named(); // Ok
}

class F {
  final A a1;
  final A a2;

  F(this.a1, this.a2); // Ok
  external F.named(); // Ok
}
