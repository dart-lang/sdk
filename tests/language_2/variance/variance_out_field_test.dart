// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests various fields for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

typedef Void2Int = int Function();

class A<out T> {
  final T a = null;
  final T Function() b = () => null;
  T get c => null;
  A<T> get d => this;
}

mixin BMixin<out T> {
  final T a = null;
  final T Function() b = () => null;
  T get c => null;
  BMixin<T> get d => this;
}

class B with BMixin<int> {}

void testClass() {
  A<int> a = new A();

  Expect.isNull(a.a);

  Expect.type<Void2Int>(a.b);
  Expect.isNull(a.b());

  Expect.isNull(a.c);

  Expect.isNull(a.d.a);
}

void testMixin() {
  B b = new B();

  Expect.isNull(b.a);

  Expect.type<Void2Int>(b.b);
  Expect.isNull(b.b());

  Expect.isNull(b.c);

  Expect.isNull(b.d.a);
}

main() {
  testClass();
  testMixin();
}
