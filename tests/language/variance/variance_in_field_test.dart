// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests various fields for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

typedef Int2Void = void Function(int);

class A<in T> {
  void set a(T value) => value;
  final void Function(T) b = (T val) {
    Expect.equals(2, val);
  };
  A<T> get c => this;
}

mixin BMixin<in T> {
  void set a(T value) => value;
  final void Function(T) b = (T val) {
    Expect.equals(2, val);
  };
  BMixin<T> get c => this;
}

class B with BMixin<int> {}

void testClass() {
  A<int> a = new A();

  a.a = 2;

  Expect.type<Int2Void>(a.b);
  a.b(2);

  a.c.a = 2;
}

void testMixin() {
  B b = new B();

  b.a = 2;

  Expect.type<Int2Void>(b.b);
  b.b(2);

  b.c.a = 2;
}

main() {
  testClass();
  testMixin();
}
