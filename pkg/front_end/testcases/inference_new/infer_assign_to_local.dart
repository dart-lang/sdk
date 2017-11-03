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
}

class C extends B {}

T f<T>() => null;

void test() {
  B local;
  local = /*@typeArgs=B*/ f();
  local ??= /*@typeArgs=B*/ f();
  local += /*@typeArgs=dynamic*/ f();
  local *= /*@typeArgs=dynamic*/ f();
  local &= /*@typeArgs=dynamic*/ f();
  --local;
  local--;
  var /*@type=B*/ v1 = local = /*@typeArgs=B*/ f();
  var /*@type=B*/ v2 = local ??= /*@typeArgs=B*/ f();
  var /*@type=B*/ v3 = local += /*@typeArgs=dynamic*/ f();
  var /*@type=B*/ v4 = local *= /*@typeArgs=dynamic*/ f();
  var /*@type=C*/ v5 = local &= /*@typeArgs=dynamic*/ f();
  var /*@type=B*/ v6 = --local;
  var /*@type=B*/ v7 = local--;
}

main() {}
