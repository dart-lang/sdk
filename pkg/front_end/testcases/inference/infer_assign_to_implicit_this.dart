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

class Test {
  B member;

  void test() {
    /*@target=Test::member*/ member = /*@typeArgs=B*/ f();
    /*@target=Test::member*/ member ??= /*@typeArgs=B*/ f();
    /*@target=Test::member*/ member += /*@typeArgs=dynamic*/ f();
    /*@target=Test::member*/ member *= /*@typeArgs=dynamic*/ f();
    /*@target=Test::member*/ member &= /*@typeArgs=dynamic*/ f();
    -- /*@target=Test::member*/ member;
    /*@target=Test::member*/ member--;
    var /*@type=B*/ v1 = /*@target=Test::member*/ member = /*@typeArgs=B*/ f();
    var /*@type=B*/ v2 = /*@target=Test::member*/ member ??= /*@typeArgs=B*/ f();
    var /*@type=B*/ v4 = /*@target=Test::member*/ member *= /*@typeArgs=dynamic*/ f();
    var /*@type=C*/ v5 = /*@target=Test::member*/ member &= /*@typeArgs=dynamic*/ f();
    var /*@type=B*/ v6 = -- /*@target=Test::member*/ member;
    var /*@type=B*/ v7 = /*@target=Test::member*/ member--;
  }
}

main() {}
