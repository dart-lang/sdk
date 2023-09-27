// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A(); // OK
}

class B {
  int a = 0;
  int b = 0;

  B(this.a, [this.b = 0]); // OK because field formal parameters are being used
}

class C {
  int a;
  int b;

  C({this.a = 0, this.b = 0}); // OK because field formal parameters are being used
}

class D {
  D(int a, // LINT
    [int b = 5]); // LINT
}

class E {
  int c = 0;

  E(int a, {int b = 10}) { // OK because all parameters are used
    c = a + b;
  }
}

class F {
  int n = 0;

  F(int a, [int b = 10, // LINT
    int c = 42]) { // LINT
    n = a + 42;
  }
}

class G {
  int c = 0;
  int d = 0;

  G(int a, {int b = 0, this.c = 0}) { // OK because all non-field-formal parameters are used
    d = a + b;
  }
}

class H {
  int c;

  H(int a, int b) : c = a + b; // OK because parameters are used in initializer
}

class I extends H {
  I(int a, int b) : super(a, b); // OK because parameters are used in initializer
}

class J extends H {
  int d = 0;

  J(int a, int b, int c) : super(a, b) { // OK because all parameters are used
    d = a * b * c;
  }
}

class K {
  int a = 0;
  int b = 0;

  K(this.a, {this.b = 0, int c = 0}); // LINT
}

class L {
  int c;

  L(int a, int b) : c = a + b;
  L.named(int a, int b, int c) : this(a, b); // LINT
}

class M {
  M._internal(int n); // LINT

  factory M(int a, int b) => M._internal(a); // LINT
  factory M.redirect(int n) = M._internal; // OK because target constructor have parameters
}

class N {
  external N(int n); // OK
  external factory N.named(int n); // OK
}

class O {
  O(@Deprecated('') int x); // OK because the parameter is deprecated
}

class P {
  P(int _, Object __); // OK by naming convention: https://github.com/dart-lang/linter/issues/1793
}
