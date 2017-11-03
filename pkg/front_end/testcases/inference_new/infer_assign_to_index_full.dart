// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Index {}

class A {}

class B extends A {
  A operator +(C v) => null;
  B operator -(int i) => null;
  B operator *(B v) => null;
  C operator &(A v) => null;
}

class C extends B {}

T f<T>() => null;

class Test {
  B operator [](Index i) => null;
  void operator []=(Index i, B v) {}

  void test() {
    Test t = /*@typeArgs=Test*/ f();
    t /*@target=Test::[]=*/ [/*@typeArgs=dynamic*/ f()] = /*@typeArgs=B*/ f();
    t /*@target=Test::[]=*/ [/*@typeArgs=dynamic*/ f()] ??= /*@typeArgs=B*/ f();
    t /*@target=Test::[]=*/ [
        /*@typeArgs=dynamic*/ f()] += /*@typeArgs=dynamic*/ f();
    t /*@target=Test::[]=*/ [
        /*@typeArgs=dynamic*/ f()] *= /*@typeArgs=dynamic*/ f();
    t /*@target=Test::[]=*/ [
        /*@typeArgs=dynamic*/ f()] &= /*@typeArgs=dynamic*/ f();
    --t /*@target=Test::[]=*/ [/*@typeArgs=dynamic*/ f()];
    t /*@target=Test::[]=*/ [/*@typeArgs=dynamic*/ f()]--;
    var /*@type=B*/ v1 = t /*@target=Test::[]=*/ [
        /*@typeArgs=dynamic*/ f()] = /*@typeArgs=B*/ f();
    var /*@type=B*/ v2 = t /*@target=Test::[]=*/ [
        /*@typeArgs=dynamic*/ f()] ??= /*@typeArgs=B*/ f();
    var /*@type=B*/ v3 = t /*@target=Test::[]=*/ [
        /*@typeArgs=dynamic*/ f()] += /*@typeArgs=dynamic*/ f();
    var /*@type=B*/ v4 = t /*@target=Test::[]=*/ [
        /*@typeArgs=dynamic*/ f()] *= /*@typeArgs=dynamic*/ f();
    var /*@type=C*/ v5 = t /*@target=Test::[]=*/ [
        /*@typeArgs=dynamic*/ f()] &= /*@typeArgs=dynamic*/ f();
    var /*@type=B*/ v6 = --t /*@target=Test::[]=*/ [/*@typeArgs=dynamic*/ f()];
    var /*@type=B*/ v7 = t /*@target=Test::[]=*/ [/*@typeArgs=dynamic*/ f()]--;
  }
}

main() {}
