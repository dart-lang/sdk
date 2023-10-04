// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

@immutable
class A {
  const A(); // OK
  A.c1(); // LINT
  const A.c2(); // OK
  // no lint for constructor with body
  A.c3() // OK
  {}
}

class B extends A {
  B.c1(); // LINT
  const B.c2(); // OK
  // no lint for constructor with non-const super call
  B.c3() : super.c1(); // OK
  B.c4() : super.c2(); // LINT
}

class C implements A {
  // no lint with implements
  C.c1(); // OK
  const C.c2(); // OK
}

@immutable
class D {
  final _a;
  Object get a => _a;
  // no lint when there's a non const expression in initializer list
  D.c1(a) : _a = a.toString(); // OK
  D.c2(a) : _a = a; // LINT
  D.c3(bool a) : _a = a && a; // LINT
  D.c4(a) : _a = '${a ? a : ''}'; // LINT
}

mixin Mixin1 {}

class E extends A with Mixin1 {
  // no lint because const leads to error : Const constructor can't be declared for a class with a mixin.
  E.c1(); // OK
}

@immutable
class F {
  const factory F.fc1() = F.c1; // OK
  factory F.fc2() = F.c1; // LINT
  const F.c1();
}

@immutable
class G {
  G.a(); // LINT
  G.b() : this.a(); // OK
  const G.c(); // OK
  G.d() : this.c(); // LINT
  const G.e() : this.c(); // OK
}

@immutable
class H {
  final f;
  H(f) : f = f ?? f == null; // LINT
}

int not_const = 0;

@immutable
class HH {
  final f;
  HH(f) : f = not_const; // OK
}

// no lint for class with final field initialized with new
@immutable
class I {
  final f = new Object();
  I(f); // OK
}

// no lint for factory redirected to non const constructor
@immutable
class J {
  factory J.f1() = J.c1; // OK
  factory J.f2() = J.c2; // LINT
  J.c1() {} // OK
  const J.c2(); // OK
}
