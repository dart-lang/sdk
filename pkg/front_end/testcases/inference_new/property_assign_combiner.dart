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
  A get target => null;

  void set target(B value) {}
}

void test1(G g) {
  /*@ type=G* */ g. /*@target=G.target*/ /*@target=G.target*/ target
      /*@target=A.**/ *=
      /*@ typeArgs=D* */ f();
  var /*@ type=C* */ x =
      /*@ type=G* */ g. /*@target=G.target*/ /*@target=G.target*/ target
          /*@target=A.**/ *=
          /*@ typeArgs=D* */ f();
}

void test2(G g) {
  /*@target=A.+*/ ++ /*@ type=G* */ g
      . /*@target=G.target*/ /*@target=G.target*/ target;
  var /*@ type=C* */ x = /*@target=A.+*/ ++ /*@ type=G* */ g
      . /*@target=G.target*/ /*@target=G.target*/ target;
}

void test3(G g) {
  /*@ type=G* */ g
      . /*@target=G.target*/ /*@target=G.target*/ target /*@target=A.+*/ ++;
  var /*@ type=A* */ x = /*@ type=G* */ g. /*@ type=A* */ /*@target=G.target*/
          /*@target=G.target*/ /*@ type=C* */ target
      /*@target=A.+*/ ++;
}

main() {}
