// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>() => null;

class A {
  C operator +(int value) => null;
  C operator *(D value) => null;
}

class B {
  E operator +(int value) => null;
  E operator *(F value) => null;
}

class C extends B {}

class D {}

class E {}

class F {}

A get target => null;

void set target(B value) {}

void test1() {
  target /*@target=A.**/ *= /*@ typeArgs=D* */ f();
  var /*@ type=C* */ x = target /*@target=A.**/ *= /*@ typeArgs=D* */ f();
}

void test2() {
  /*@target=A.+*/ ++target;
  var /*@ type=C* */ x = /*@target=A.+*/ ++target;
}

void test3() {
  target /*@target=A.+*/ ++;
  var /*@ type=A* */ x = /*@ type=A* */ target
      /*@ type=C* */ /*@target=A.+*/ ++;
}

main() {}
