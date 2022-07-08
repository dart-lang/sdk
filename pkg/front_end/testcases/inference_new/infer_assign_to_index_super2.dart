// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Index {}

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
  B operator [](Index i) => throw '';
  void operator []=(Index i, B v) {}
}

class Test extends Base {
  void test() {
    super /*@target=Base.[]=*/ [/*@typeArgs=Index*/ f()] = /*@typeArgs=B*/ f();

    super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        /*@typeArgs=Index*/ f()] /*@target=B.+*/ += /*@typeArgs=C*/ f();

    super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        /*@typeArgs=Index*/ f()] /*@target=B.**/ *= /*@typeArgs=B*/ f();

    super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        /*@typeArgs=Index*/ f()] /*@target=B.&*/ &= /*@typeArgs=A*/ f();

    /*@target=B.-*/ --super /*@target=Base.[]*/ /*@target=Base.[]=*/
        [/*@typeArgs=Index*/ f()];

    super /*@target=Base.[]*/ /*@target=Base.[]=*/
        [/*@typeArgs=Index*/ f()] /*@target=B.-*/ --;

    var /*@type=B*/ v1 = super /*@target=Base.[]=*/ [
        /*@typeArgs=Index*/ f()] = /*@typeArgs=B*/ f();

    var /*@type=B*/ v3 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        /*@typeArgs=Index*/ f()] /*@target=B.+*/ += /*@typeArgs=C*/ f();

    var /*@type=B*/ v4 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        /*@typeArgs=Index*/ f()] /*@target=B.**/ *= /*@typeArgs=B*/ f();

    var /*@type=C*/ v5 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        /*@typeArgs=Index*/ f()] /*@target=B.&*/ &= /*@typeArgs=A*/ f();

    var /*@type=B*/ v6 = /*@target=B.-*/ --super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        /*@typeArgs=Index*/ f()];

    var /*@type=B*/ v7 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        [/*@typeArgs=Index*/ f()] /*@target=B.-*/ --;
  }
}

class Base2 {
  B? operator [](Index i) => throw '';
  void operator []=(Index i, B? v) {}
}

class Test2 extends Base2 {
  void test() {
    super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ [
        /*@typeArgs=Index*/ f()] ??= /*@typeArgs=B?*/ f();

    var /*@type=B?*/ v2 = super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ [
        /*@typeArgs=Index*/ f()] ??= /*@typeArgs=B?*/ f();
  }
}

main() {}
