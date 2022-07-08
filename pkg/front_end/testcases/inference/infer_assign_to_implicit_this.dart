// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {}

class B extends A {
  A operator +(C v) => throw '';
  B operator -(int i) => throw '';
  B operator *(B v) => throw '';
  C operator &(A v) => throw '';
}

class C extends B {}

T f<T>() => throw '';

class Test {
  B member;
  B? member2;

  Test(this.member, this.member2);

  void test() {
    /*@target=Test.member*/ member = /*@typeArgs=B*/ f();

    /*@target=Test.member2*/ /*@target=Test.member2*/ member2
         ??= /*@typeArgs=B?*/ f();

    /*@target=Test.member*/ /*@target=Test.member*/ member
        /*@target=B.+*/ += /*@typeArgs=C*/ f();

    /*@target=Test.member*/ /*@target=Test.member*/ member
        /*@target=B.**/ *= /*@typeArgs=B*/ f();

    /*@target=Test.member*/ /*@target=Test.member*/ member
        /*@target=B.&*/ &= /*@typeArgs=A*/ f();

    /*@target=B.-*/ -- /*@target=Test.member*/ /*@target=Test.member*/
        member;

    /*@target=Test.member*/ /*@target=Test.member*/ member
        /*@target=B.-*/ --;

    var /*@type=B*/ v1 = /*@target=Test.member*/ member =
        /*@typeArgs=B*/ f();

    var /*@type=B?*/ v2 = /*@target=Test.member2*/ /*@target=Test.member2*/
        member2  ??= /*@typeArgs=B?*/ f();

    var /*@type=A*/ v3 = /*@target=Test.member*/ /*@target=Test.member*/
        member /*@target=B.+*/ +=
            /*@typeArgs=C*/ f();

    var /*@type=B*/ v4 = /*@target=Test.member*/ /*@target=Test.member*/
        member /*@target=B.**/ *=
            /*@typeArgs=B*/ f();

    var /*@type=C*/ v5 = /*@target=Test.member*/ /*@target=Test.member*/
        member /*@target=B.&*/ &=
            /*@typeArgs=A*/ f();

    var /*@type=B*/ v6 = /*@target=B.-*/ --
        /*@target=Test.member*/ /*@target=Test.member*/ member;

    var /*@type=B*/ v7 =
        /*@type=B*/ /*@target=Test.member*/ /*@target=Test.member*/
        /*@type=B*/ member /*@target=B.-*/ --;
  }
}

main() {}
