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

class G {
  A operator [](int i) => null;

  void operator []=(int i, B value) {}
}

void test1(G g) {
  g /*@target=G::[]=*/ [0] *= /*@typeArgs=dynamic*/ f();
  var /*@type=C*/ x = g /*@target=G::[]=*/ [0] *= /*@typeArgs=dynamic*/ f();
}

void test2(G g) {
  ++g /*@target=G::[]=*/ [0];
  var /*@type=C*/ x = ++g /*@target=G::[]=*/ [0];
}

void test3(G g) {
  g /*@target=G::[]=*/ [0]++;
  var /*@type=A*/ x = g /*@target=G::[]=*/ [0]++;
}

main() {}
