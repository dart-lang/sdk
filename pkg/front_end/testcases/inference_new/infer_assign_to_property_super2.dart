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

class Base {
  B member = throw '';
  B? member2;
}

class Test extends Base {
  void test() {
    super.member = /*@typeArgs=B*/ f();

    super. /*@target=Base.member2*/ member2 ??= /*@typeArgs=B?*/ f();

    super
        . /*@target=Base.member*/ member /*@target=B.+*/ += /*@typeArgs=C*/ f();

    super
        . /*@target=Base.member*/ member /*@target=B.**/ *= /*@typeArgs=B*/ f();

    super
        . /*@target=Base.member*/ member /*@target=B.&*/ &= /*@typeArgs=A*/ f();

    /*@target=B.-*/ --super. /*@target=Base.member*/ member;

    super. /*@target=Base.member*/ member /*@target=B.-*/ --;

    var /*@type=B*/ v1 = super.member = /*@typeArgs=B*/ f();

    var /*@type=B?*/ v2 =
        super. /*@target=Base.member2*/ member2 ??= /*@typeArgs=B?*/ f();

    var /*@type=B*/ v3 = super
        . /*@target=Base.member*/ member /*@target=B.+*/ += /*@typeArgs=C*/ f();

    var /*@type=B*/ v4 = super
        . /*@target=Base.member*/ member /*@target=B.**/ *= /*@typeArgs=B*/ f();

    var /*@type=C*/ v5 = super
        . /*@target=Base.member*/ member /*@target=B.&*/ &= /*@typeArgs=A*/ f();

    var /*@type=B*/ v6 = /*@target=B.-*/ --super
        . /*@target=Base.member*/ member;

    var /*@type=B*/ v7 = super
        .
        /*@type=B*/ /*@target=Base.member*/
        /*@type=B*/ member /*@target=B.-*/ --;
  }
}

main() {}
