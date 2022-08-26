// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
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
  topLevelVariable = /*@typeArgs=B*/ f();

  topLevelVariable2 ??= /*@typeArgs=B?*/ f();

  topLevelVariable /*@target=B.+*/ += /*@typeArgs=C*/ f();

  topLevelVariable /*@target=B.**/ *= /*@typeArgs=B*/ f();

  topLevelVariable /*@target=B.&*/ &= /*@typeArgs=A*/ f();

  /*@target=B.-*/ --topLevelVariable;

  topLevelVariable /*@target=B.-*/ --;

  var /*@type=B*/ v1 = topLevelVariable = /*@typeArgs=B*/ f();

  var /*@type=B?*/ v2 = topLevelVariable2 ??= /*@typeArgs=B?*/ f();

  var /*@type=B*/ v3 = topLevelVariable /*@target=B.+*/ += /*@typeArgs=C*/ f();

  var /*@type=B*/ v4 = topLevelVariable /*@target=B.**/ *= /*@typeArgs=B*/ f();

  var /*@type=C*/ v5 = topLevelVariable /*@target=B.&*/ &= /*@typeArgs=A*/ f();

  var /*@type=B*/ v6 = /*@target=B.-*/ --topLevelVariable;

  var /*@type=B*/ v7 = /*@type=B*/ topLevelVariable /*@type=B*/ /*@target=B.-*/ --;
}

void test_staticVariable() {
  B.staticVariable = /*@typeArgs=B*/ f();

  B.staticVariable2 ??= /*@typeArgs=B?*/ f();

  B.staticVariable /*@target=B.+*/ += /*@typeArgs=C*/ f();

  B.staticVariable /*@target=B.**/ *= /*@typeArgs=B*/ f();

  B.staticVariable /*@target=B.&*/ &= /*@typeArgs=A*/ f();

  /*@target=B.-*/ --B.staticVariable;

  B.staticVariable /*@target=B.-*/ --;

  var /*@type=B*/ v1 = B.staticVariable = /*@typeArgs=B*/ f();

  var /*@type=B?*/ v2 = B.staticVariable2 ??= /*@typeArgs=B?*/ f();

  var /*@type=B*/ v3 = B.staticVariable /*@target=B.+*/ += /*@typeArgs=C*/ f();

  var /*@type=B*/ v4 = B.staticVariable /*@target=B.**/ *= /*@typeArgs=B*/ f();

  var /*@type=C*/ v5 = B.staticVariable /*@target=B.&*/ &= /*@typeArgs=A*/ f();

  var /*@type=B*/ v6 = /*@target=B.-*/ --B.staticVariable;

  var /*@type=B*/ v7 =
      B. /*@type=B*/ staticVariable /*@type=B*/ /*@target=B.-*/ --;
}

main() {}
