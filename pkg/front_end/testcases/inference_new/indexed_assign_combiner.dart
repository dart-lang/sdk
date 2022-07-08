// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>() => throw '';

class A {
  C operator +(int value) => throw '';
  C operator *(D value) => throw '';
}

class B {
  E operator +(int value) => throw '';
  E operator *(F value) => throw '';
}

class C extends B {}

class D {}

class E {}

class F {}

class G {
  A operator [](int i) => throw '';

  void operator []=(int i, B value) {}
}

void test1(G g) {
  g /*@target=G.[]*/ /*@target=G.[]=*/ [
      0] /*@target=A.**/ *= /*@typeArgs=D*/ f();
  var /*@type=C*/ x = g /*@target=G.[]*/ /*@target=G.[]=*/ [0]
      /*@target=A.**/
      *= /*@typeArgs=D*/ f();
}

void test2(G g) {
  /*@target=A.+*/ ++g /*@target=G.[]*/ /*@target=G.[]=*/ [0];
  var /*@type=C*/ x = /*@target=A.+*/ ++g /*@target=G.[]*/ /*@target=G.[]=*/ [
      0];
}

void test3(G g) {
  g /*@target=G.[]*/ /*@target=G.[]=*/ [0] /*@target=A.+*/ ++;
  var /*@type=A*/ x =
      g /*@target=G.[]*/ /*@target=G.[]=*/ [0] /*@target=A.+*/ ++;
}

main() {}
