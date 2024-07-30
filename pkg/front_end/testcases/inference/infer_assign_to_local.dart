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
}

class C extends B {}

T f<T>() => throw '';

void test(B local, B? local2, B? local3) {
  local = /*@typeArgs=B*/ f();

  local2 ??= /*@typeArgs=B?*/ f();

  local /*@target=B.+*/ += /*@typeArgs=C*/ f();

  local /*@target=B.**/ *= /*@typeArgs=B*/ f();

  local /*@target=B.&*/ &= /*@typeArgs=A*/ f();

  /*@target=B.-*/ --local;

  local /*@target=B.-*/ --;

  var /*@type=B*/ v1 = local = /*@typeArgs=B*/ f();

  var /*@type=B?*/ v2 = local3 ??= /*@typeArgs=B?*/ f();

  var /*@type=B*/ v3 = local /*@target=B.+*/ += /*@typeArgs=C*/ f();

  var /*@type=B*/ v4 = local /*@target=B.**/ *= /*@typeArgs=B*/ f();

  var /*@type=C*/ v5 = local /*@target=B.&*/ &= /*@typeArgs=A*/ f();

  var /*@type=B*/ v6 = /*@target=B.-*/ --local;

  var /*@type=B*/ v7 = /*@type=B*/ local /*@type=B*/ /*@target=B.-*/ --;
}

main() {}
