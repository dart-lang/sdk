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

class Test {
  B operator [](Index i) => throw '';
  void operator []=(Index i, B v) {}

  void test() {
    this /*@target=Test.[]=*/ [/*@typeArgs=Index*/ f()] = /*@typeArgs=B*/ f();

    this /*@target=Test.[]*/ /*@target=Test.[]=*/ [
            /*@typeArgs=Index*/ f()] /*@target=B.+*/
        += /*@typeArgs=C*/ f();

    this /*@target=Test.[]*/ /*@target=Test.[]=*/ [
            /*@typeArgs=Index*/ f()] /*@target=B.**/
        *= /*@typeArgs=B*/ f();

    this /*@target=Test.[]*/ /*@target=Test.[]=*/ [
            /*@typeArgs=Index*/ f()] /*@target=B.&*/
        &= /*@typeArgs=A*/ f();

    /*@target=B.-*/ --this /*@target=Test.[]*/ /*@target=Test.[]=*/ [
        /*@typeArgs=Index*/ f()];

    this /*@target=Test.[]*/ /*@target=Test.[]=*/ [
        /*@typeArgs=Index*/ f()] /*@target=B.-*/ --;

    var /*@type=B*/ v1 = this /*@target=Test.[]=*/ [
        /*@typeArgs=Index*/ f()] = /*@typeArgs=B*/ f();

    var /*@type=B*/ v4 = this /*@target=Test.[]*/ /*@target=Test.[]=*/ [
            /*@typeArgs=Index*/ f()] /*@target=B.+*/
        += /*@typeArgs=C*/ f();

    var /*@type=B*/ v3 = this /*@target=Test.[]*/ /*@target=Test.[]=*/ [
            /*@typeArgs=Index*/ f()] /*@target=B.**/
        *= /*@typeArgs=B*/ f();

    var /*@type=C*/ v5 = this /*@target=Test.[]*/ /*@target=Test.[]=*/ [
            /*@typeArgs=Index*/ f()] /*@target=B.&*/
        &= /*@typeArgs=A*/ f();

    var /*@type=B*/ v6 = /*@target=B.-*/ --this /*@target=Test.[]*/ /*@target=Test.[]=*/ [
        /*@typeArgs=Index*/ f()];

    var /*@type=B*/ v7 = this /*@target=Test.[]*/ /*@target=Test.[]=*/ [
        /*@typeArgs=Index*/ f()] /*@target=B.-*/ --;
  }
}

class Test2 {
  B? operator [](Index i) => throw '';
  void operator []=(Index i, B? v) {}

  void test() {
    this /*@target=Test2.[]*/ /*@target=Test2.[]=*/ [
        /*@typeArgs=Index*/ f()] ??= /*@typeArgs=B?*/ f();

    var /*@type=B?*/ v2 = this /*@target=Test2.[]*/ /*@target=Test2.[]=*/ [
        /*@typeArgs=Index*/ f()] ??= /*@typeArgs=B?*/ f();
  }
}

main() {}
