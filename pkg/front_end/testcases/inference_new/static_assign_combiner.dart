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
  target *= /*@typeArgs=dynamic*/ f();
  var /*@type=C*/ x = target *= /*@typeArgs=dynamic*/ f();
}

void test2() {
  ++target;
  var /*@type=C*/ x = ++target;
}

void test3() {
  target++;
  var /*@type=A*/ x = target++;
}

main() {}
