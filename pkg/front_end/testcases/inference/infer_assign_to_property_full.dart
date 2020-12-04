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

  static void test(Test t) {
    t. /*@target=Test.member*/ member = /*@ typeArgs=B* */ f();
    /*@ type=Test* */ /*@target=Test.member*/ t. /*@target=Test.member*/ member
        /*@target=A.==*/ ??= /*@ typeArgs=B* */ f();
    /*@ type=Test* */ t. /*@target=Test.member*/ /*@target=Test.member*/ member
        /*@target=B.+*/ += /*@ typeArgs=C* */ f();
    /*@ type=Test* */ t. /*@target=Test.member*/ /*@target=Test.member*/ member
        /*@target=B.**/ *= /*@ typeArgs=B* */ f();
    /*@ type=Test* */ t. /*@target=Test.member*/ /*@target=Test.member*/ member
        /*@target=B.&*/ &= /*@ typeArgs=A* */ f();
    /*@target=B.-*/ -- /*@ type=Test* */ t
        . /*@target=Test.member*/ /*@target=Test.member*/ member;
    /*@ type=Test* */ t. /*@target=Test.member*/ /*@target=Test.member*/ member
        /*@target=B.-*/ --;
    var /*@ type=B* */ v1 =
        t. /*@target=Test.member*/ member = /*@ typeArgs=B* */ f();
    var /*@ type=B* */ v2 =
        /*@ type=Test* */ /*@target=Test.member*/ t
                . /*@target=Test.member*/ member
            /*@target=A.==*/ ??= /*@ typeArgs=B* */ f();
    var /*@ type=A* */ v3 =
        /*@ type=Test* */ t
                . /*@target=Test.member*/ /*@target=Test.member*/ member
            /*@target=B.+*/ += /*@ typeArgs=C* */ f();
    var /*@ type=B* */ v4 =
        /*@ type=Test* */ t
                . /*@target=Test.member*/ /*@target=Test.member*/ member
            /*@target=B.**/ *= /*@ typeArgs=B* */ f();
    var /*@ type=C* */ v5 =
        /*@ type=Test* */ t
                . /*@target=Test.member*/ /*@target=Test.member*/ member
            /*@target=B.&*/ &= /*@ typeArgs=A* */ f();
    var /*@ type=B* */ v6 = /*@target=B.-*/ -- /*@ type=Test* */ t
        . /*@target=Test.member*/ /*@target=Test.member*/ member;
    var /*@ type=B* */ v7 = /*@ type=Test* */ t
        . /*@ type=B* */ /*@target=Test.member*/ /*@target=Test.member*/
        /*@ type=B* */ member /*@target=B.-*/ --;
  }
}

main() {}
