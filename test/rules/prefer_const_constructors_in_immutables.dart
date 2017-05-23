// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_const_constructors_in_immutables`

// Hack to work around issues importing `meta.dart` in tests.
// Ideally, remove:
library meta;

class _Immutable {
  const _Immutable();
}

const _Immutable immutable = const _Immutable();

@immutable
class A {
  const A(); // OK
  A.c1(); // LINT
  const A.c2(); // OK
}

class B extends A {
  B.c1(); // LINT
  const B.c2(); // OK
  B.c3() : super.c1(); // OK
  B.c4() : super.c2(); // LINT
}

class C implements A {
  C.c1(); // OK
  const C.c2(); // OK
}

@immutable
class D {
  final _a;
  // not a const expression in initializer list
  D.c1(a) : _a = a.toString(); // OK
  D.c2(a) : _a = a; // LINT
  D.c3(bool a) : _a = a && a; // LINT
}
