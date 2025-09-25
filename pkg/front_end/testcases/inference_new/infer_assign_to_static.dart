// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class A {}

class B extends A {
  B operator +(C v) => throw '';
  B operator -(int i) => throw '';
  B operator *(B v) => throw '';
  C operator &(A v) => throw '';

  static B staticVariable = throw '';
  static B? staticVariable2;
}

class C extends B {}

T f<T>() => throw '';

B topLevelVariable = throw '';
B? topLevelVariable2;

void test_topLevelVariable() {
  topLevelVariable = f();

  topLevelVariable2 ??= f();

  topLevelVariable += f();

  topLevelVariable *= f();

  topLevelVariable &= f();

  --topLevelVariable;

  topLevelVariable--;

  var v1 = topLevelVariable = f();

  var v2 = topLevelVariable2 ??= f();

  var v3 = topLevelVariable += f();

  var v4 = topLevelVariable *= f();

  var v5 = topLevelVariable &= f();

  var v6 = --topLevelVariable;

  var v7 = topLevelVariable--;
}

void test_staticVariable() {
  B.staticVariable = f();

  B.staticVariable2 ??= f();

  B.staticVariable += f();

  B.staticVariable *= f();

  B.staticVariable &= f();

  --B.staticVariable;

  B.staticVariable--;

  var v1 = B.staticVariable = f();

  var v2 = B.staticVariable2 ??= f();

  var v3 = B.staticVariable += f();

  var v4 = B.staticVariable *= f();

  var v5 = B.staticVariable &= f();

  var v6 = --B.staticVariable;

  var v7 = B.staticVariable--;
}

main() {}
