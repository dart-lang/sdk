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

class Test {
  B member;
  B? member2;

  Test(this.member);

  static void test(Test t) {
    t. /*@target=Test.member*/ member = /*@typeArgs=B*/ f();
    /*@type=Test*/ /*@target=Test.member2*/ t
        . /*@target=Test.member2*/ member2 ??= /*@typeArgs=B?*/ f();
    /*@type=Test*/ t
        . /*@target=Test.member*/ /*@target=Test.member*/ member /*@target=B.+*/ += /*@typeArgs=C*/ f();
    /*@type=Test*/ t
        . /*@target=Test.member*/ /*@target=Test.member*/ member /*@target=B.**/ *= /*@typeArgs=B*/ f();
    /*@type=Test*/ t
        . /*@target=Test.member*/ /*@target=Test.member*/ member /*@target=B.&*/ &= /*@typeArgs=A*/ f();
    /*@target=B.-*/ -- /*@type=Test*/ t
        . /*@target=Test.member*/ /*@target=Test.member*/ member;
    /*@type=Test*/ t
        . /*@target=Test.member*/ /*@target=Test.member*/ member /*@target=B.-*/ --;
    var /*@type=B*/ v1 =
        t. /*@target=Test.member*/ member = /*@typeArgs=B*/ f();
    var /*@type=B?*/ v2 = /*@type=Test*/ /*@target=Test.member2*/ t
        . /*@target=Test.member2*/ member2 ??= /*@typeArgs=B?*/ f();
    var /*@type=B*/ v3 = /*@type=Test*/ t
        . /*@target=Test.member*/ /*@target=Test.member*/ member /*@target=B.+*/ += /*@typeArgs=C*/ f();
    var /*@type=B*/ v4 = /*@type=Test*/ t
        . /*@target=Test.member*/ /*@target=Test.member*/ member /*@target=B.**/ *= /*@typeArgs=B*/ f();
    var /*@type=C*/ v5 = /*@type=Test*/ t
        . /*@target=Test.member*/ /*@target=Test.member*/ member /*@target=B.&*/ &= /*@typeArgs=A*/ f();
    var /*@type=B*/ v6 = /*@target=B.-*/ -- /*@type=Test*/ t
        . /*@target=Test.member*/ /*@target=Test.member*/ member;
    var /*@type=B*/ v7 = /*@type=Test*/ t
        . /*@type=B*/ /*@target=Test.member*/ /*@target=Test.member*/
        /*@type=B*/ member /*@target=B.-*/ --;
  }
}

main() {}
