// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {}

class B extends A {
  A operator +(C v) => null;
  B operator -(int i) => null;
  B operator *(B v) => null;
  C operator &(A v) => null;

  static B staticVariable;
}

class C extends B {}

T f<T>() => null;

B topLevelVariable;

void test_topLevelVariable() {
  topLevelVariable = /*@typeArgs=B*/ f();
  topLevelVariable ??= /*@typeArgs=B*/ f();
  topLevelVariable += /*@typeArgs=dynamic*/ f();
  topLevelVariable *= /*@typeArgs=dynamic*/ f();
  topLevelVariable &= /*@typeArgs=dynamic*/ f();
  --topLevelVariable;
  topLevelVariable--;
  var /*@type=B*/ v1 = topLevelVariable = /*@typeArgs=B*/ f();
  var /*@type=B*/ v2 = topLevelVariable ??= /*@typeArgs=B*/ f();
  var /*@type=B*/ v3 = topLevelVariable += /*@typeArgs=dynamic*/ f();
  var /*@type=B*/ v4 = topLevelVariable *= /*@typeArgs=dynamic*/ f();
  var /*@type=C*/ v5 = topLevelVariable &= /*@typeArgs=dynamic*/ f();
  var /*@type=B*/ v6 = --topLevelVariable;
  var /*@type=B*/ v7 = topLevelVariable--;
}

void test_staticVariable() {
  B.staticVariable = /*@typeArgs=B*/ f();
  B.staticVariable ??= /*@typeArgs=B*/ f();
  B.staticVariable += /*@typeArgs=dynamic*/ f();
  B.staticVariable *= /*@typeArgs=dynamic*/ f();
  B.staticVariable &= /*@typeArgs=dynamic*/ f();
  --B.staticVariable;
  B.staticVariable--;
  var /*@type=B*/ v1 = B.staticVariable = /*@typeArgs=B*/ f();
  var /*@type=B*/ v2 = B.staticVariable ??= /*@typeArgs=B*/ f();
  var /*@type=B*/ v3 = B.staticVariable += /*@typeArgs=dynamic*/ f();
  var /*@type=B*/ v4 = B.staticVariable *= /*@typeArgs=dynamic*/ f();
  var /*@type=C*/ v5 = B.staticVariable &= /*@typeArgs=dynamic*/ f();
  var /*@type=B*/ v6 = --B.staticVariable;
  var /*@type=B*/ v7 = B.staticVariable--;
}

main() {}
