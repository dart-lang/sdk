// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_field_initializers_in_const_classes`

class A {
  final a = const []; // LINT
  const A();
}

class B {
  final a;
  const B() //
      : a = const []; // LINT
}

class C {
  final a;
  const C(this.a); // OK
}

class D {
  final a;
  const D(b) //
      : a = b; // OK
}

// no lint if several constructors
class E {
  final a;
  const E.c1() //
      : a = const []; // OK
  const E.c2() //
      : a = const {}; // OK
}

class F {
  final a;
  const F(int a) : this.a = 0; // LINT
}

class G {
  final g;
  const G(int length) : g = 'xyzzy'.length; // LINT
}

mixin M {
  final a = const []; // OK
}
