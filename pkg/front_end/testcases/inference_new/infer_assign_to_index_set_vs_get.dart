// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Index {}

class A {
  C operator +(F v) => null;
  C operator -(int i) => null;
}

class B extends A {
  D operator +(E v) => null;
  D operator -(int i) => null;
}

class C extends B {}

class D extends C {}

class E extends D {}

class F extends E {}

T f<T>() => null;

class Test {
  B operator [](Index i) => null;
  void operator []=(Index i, A v) {}

  void test() {
    Test t = /*@ typeArgs=Test* */ f();

    t /*@target=Test.[]=*/ [
        /*@ typeArgs=Index* */ f()] = /*@ typeArgs=A* */ f();

    t /*@target=Test.[]*/ /*@target=Test.[]=*/ [/*@ typeArgs=Index* */ f()]
        /*@target=A.==*/ ??= /*@ typeArgs=A* */ f();

    t /*@target=Test.[]*/ /*@target=Test.[]=*/ [/*@ typeArgs=Index* */ f()]
        /*@target=B.+*/ += /*@ typeArgs=E* */ f();

    /*@target=B.-*/ --t /*@target=Test.[]*/ /*@target=Test.[]=*/ [
        /*@ typeArgs=Index* */ f()];

    t /*@target=Test.[]*/ /*@target=Test.[]=*/ [
        /*@ typeArgs=Index* */ f()] /*@target=B.-*/ --;

    var /*@ type=A* */ v1 = t /*@target=Test.[]=*/ [
        /*@ typeArgs=Index* */ f()] = /*@ typeArgs=A* */ f();

    var /*@ type=A* */ v2 = t /*@target=Test.[]*/ /*@target=Test.[]=*/ [
            /*@ typeArgs=Index* */ f()]
        /*@target=A.==*/ ??= /*@ typeArgs=A* */ f();

    var /*@ type=D* */ v3 = t /*@target=Test.[]*/ /*@target=Test.[]=*/ [
            /*@ typeArgs=Index* */ f()]
        /*@target=B.+*/ += /*@ typeArgs=E* */ f();

    var /*@ type=D* */ v4 =
        /*@target=B.-*/ --t /*@target=Test.[]*/ /*@target=Test.[]=*/ [
            /*@ typeArgs=Index* */ f()];

    var /*@ type=B* */ v5 = t /*@target=Test.[]*/ /*@target=Test.[]=*/ [
        /*@ typeArgs=Index* */ f()] /*@target=B.-*/ --;
  }
}

main() {}
