// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var g = e.field;

var f = d.field;

E e = E(C(42));

D d = D(C(42));

extension type E(C c) implements C {}

extension type D(C c) implements B {}

class C implements B {
  final field;

  C(this.field);
}

abstract class B implements A {
  get field;
}

abstract class A {
  int get field;
}
