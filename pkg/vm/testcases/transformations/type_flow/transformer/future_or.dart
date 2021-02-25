// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

dynamic usedObject;

void use(dynamic object) {
  usedObject ??= object;
}

class A {}

class B extends A {}

void foo1_a1(x) {
  use(x);
}

void foo1_a2(x) {
  use(x);
}

void foo1_a3(x) {
  use(x);
}

void foo1_a4(x) {
  use(x);
}

void foo1(Future<A> a1, A a2, FutureOr<A> a3, FutureOr<A> a4) {
  foo1_a1(a1);
  foo1_a2(a2);
  foo1_a3(a3);
  foo1_a4(a4);
}

void foo2_a1(x) {
  use(x);
}

void foo2_a2(x) {
  use(x);
}

void foo2_a3(x) {
  use(x);
}

void foo2_a4(x) {
  use(x);
}

void foo2(Future<A> a1, A a2, FutureOr<A> a3, FutureOr<A> a4) {
  foo2_a1(a1);
  foo2_a2(a2);
  foo2_a3(a3);
  foo2_a4(a4);
}

Function unknown;
getDynamic() => unknown.call();

main(List<String> args) {
  foo1(new Future<B>.value(new B()), new B(), new Future<B>.value(new B()),
      new B());
  foo2(getDynamic(), getDynamic(), getDynamic(), getDynamic());
}
