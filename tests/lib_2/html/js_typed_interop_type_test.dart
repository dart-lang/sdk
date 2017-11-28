// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_type_test;

import 'dart:html';
import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
class A {
  var foo;

  external A(var foo);
}

@JS()
class B {
  var foo;

  external B(var foo);
}

@JS()
@anonymous
class C {
  final foo;

  external factory C({foo});
}

@JS()
@anonymous
class D {
  final foo;

  external factory D({foo});
}

class E {
  final foo;

  E(this.foo);
}

class F {
  final foo;

  F(this.foo);
}

@NoInline()
testA(A o) {
  return o.foo;
}

@NoInline()
testB(B o) {
  return o.foo;
}

@NoInline()
testC(C o) {
  return o.foo;
}

@NoInline()
testD(D o) {
  return o.foo;
}

@NoInline()
testE(E o) {
  return o.foo;
}

@NoInline()
testF(F o) {
  return o.foo;
}

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
function A(foo) {
  this.foo = foo;
}

function B(foo) {
  this.foo = foo;
}
""");
}

void expectValueOrTypeError(f(), value) {
  try {
    dynamic i = 0;
    // TODO(rnystrom): Revisit this now that checked mode is gone in 2.0.
    String s = i; // Test for checked mode.
    Expect.equals(f(), value);
  } on TypeError catch (error) {
    Expect.throwsTypeError(f);
  }
}

main() {
  _injectJs();

  dynamic a = new A(1);
  dynamic b = new B(2);
  dynamic c = new C(foo: 3);
  dynamic d = new D(foo: 4);
  dynamic e = new E(5);
  dynamic f = new F(6);

  Expect.equals(testA(a), 1);
  Expect.equals(testB(b), 2);
  Expect.equals(testA(b), 2);
  Expect.equals(testA(c), 3);
  Expect.equals(testA(d), 4);
  expectValueOrTypeError(() => testA(e), 5);
  expectValueOrTypeError(() => testA(f), 6);

  Expect.equals(testB(a), 1);
  Expect.equals(testB(b), 2);
  Expect.equals(testB(c), 3);
  Expect.equals(testB(d), 4);
  expectValueOrTypeError(() => testB(e), 5);
  expectValueOrTypeError(() => testB(f), 6);

  Expect.equals(testC(a), 1);
  Expect.equals(testC(b), 2);
  Expect.equals(testC(c), 3);
  Expect.equals(testC(d), 4);
  expectValueOrTypeError(() => testC(e), 5);
  expectValueOrTypeError(() => testC(f), 6);

  Expect.equals(testD(a), 1);
  Expect.equals(testD(b), 2);
  Expect.equals(testD(c), 3);
  Expect.equals(testD(d), 4);
  expectValueOrTypeError(() => testD(e), 5);
  expectValueOrTypeError(() => testD(f), 6);

  expectValueOrTypeError(() => testE(a), 1);
  expectValueOrTypeError(() => testE(b), 2);
  expectValueOrTypeError(() => testE(c), 3);
  expectValueOrTypeError(() => testE(d), 4);
  Expect.equals(testE(e), 5);
  expectValueOrTypeError(() => testE(f), 6);

  expectValueOrTypeError(() => testF(a), 1);
  expectValueOrTypeError(() => testF(b), 2);
  expectValueOrTypeError(() => testF(c), 3);
  expectValueOrTypeError(() => testF(d), 4);
  expectValueOrTypeError(() => testF(e), 5);
  Expect.equals(testF(f), 6);
}
