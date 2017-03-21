// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A();
}

class B extends A {
  const B();
}

class C extends A {
  const C();
  const factory C.d() = D;
}

class D extends B implements C {
  const D();
}

class Test1 {
  final A x = const A(); //# 01: ok
  final A x = const B(); //# 02: ok
  final B x = const A(); //# 03: checked mode compile-time error
  final B x = const C(); //# 04: checked mode compile-time error, static type warning
  final B x = const C.d(); //# 05: static type warning
  const Test1();
}

// Will be instantiated with U=A and V=B.
class Test2<U, V> {
  final U x = const A(); //# 06: static type warning
  final U x = const B(); //# 07: static type warning
  final V x = const A(); //# 08: checked mode compile-time error, static type warning
  final V x = const C(); //# 09: checked mode compile-time error, static type warning
  final V x = const C.d(); //# 10: static type warning
  const Test2();
}

// Will be instantiated with U=A and V=B.
class Test3<U extends A, V extends B> {
  final U x = const A(); //# 11: ok
  final U x = const B(); //# 12: static type warning
  final V x = const A(); //# 13: checked mode compile-time error
  final V x = const C(); //# 14: checked mode compile-time error, static type warning
  final V x = const C.d(); //# 15: static type warning
  const Test3();
}

// Will be instantiated with U=A and V=B.
class Test4<U extends A, V extends A> {
  final U x = const A(); //# 16: ok
  final U x = const B(); //# 17: static type warning
  final V x = const A(); //# 18: checked mode compile-time error
  final V x = const C(); //# 19: checked mode compile-time error, static type warning
  final V x = const C.d(); //# 20: static type warning
  const Test4();
}

// Will be instantiated with U=dynamic and V=dynamic.
class Test5<U extends A, V extends B> {
  final U x = const A(); //# 21: ok
  final U x = const B(); //# 22: static type warning
  final V x = const A(); //# 23: ok
  final V x = const C(); //# 24: static type warning
  final V x = const C.d(); //# 25: static type warning
  const Test5();
}

use(x) => x;

main() {
  use(const Test1());
  use(const Test2<A, B>());
  use(const Test3<A, B>());
  use(const Test4<A, B>());
  use(const Test5());
}
