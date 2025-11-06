// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

A get target => throw '';

void set target(B value) {}

void test1() {
  target *= f();
  var x = target *= f();
}

void test2() {
  ++target;
  var x = ++target;
}

void test3() {
  target++;
  var x = target++;
}

main() {}
