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

class Base {
  B operator [](Index i) => null;
  void operator []=(Index i, B v) {}
}

class Test extends Base {
  void test() {
    super /*@target=Base::[]=*/ [
        /*@typeArgs=dynamic*/ f()] = /*@typeArgs=B*/ f();
    super /*@target=Base::[]=*/ [
        /*@typeArgs=dynamic*/ f()] ??= /*@typeArgs=B*/ f();
    super /*@target=Base::[]=*/ [
        /*@typeArgs=dynamic*/ f()] += /*@typeArgs=dynamic*/ f();
    super /*@target=Base::[]=*/ [
        /*@typeArgs=dynamic*/ f()] *= /*@typeArgs=dynamic*/ f();
    super /*@target=Base::[]=*/ [
        /*@typeArgs=dynamic*/ f()] &= /*@typeArgs=dynamic*/ f();
    --super /*@target=Base::[]=*/ [/*@typeArgs=dynamic*/ f()];
    super /*@target=Base::[]=*/ [/*@typeArgs=dynamic*/ f()]--;
    var /*@type=B*/ v1 = super /*@target=Base::[]=*/ [
        /*@typeArgs=dynamic*/ f()] = /*@typeArgs=B*/ f();
    var /*@type=B*/ v2 = super /*@target=Base::[]=*/ [
        /*@typeArgs=dynamic*/ f()] ??= /*@typeArgs=B*/ f();
    var /*@type=A*/ v3 = super /*@target=Base::[]=*/ [
        /*@typeArgs=dynamic*/ f()] += /*@typeArgs=dynamic*/ f();
    var /*@type=B*/ v4 = super /*@target=Base::[]=*/ [
        /*@typeArgs=dynamic*/ f()] *= /*@typeArgs=dynamic*/ f();
    var /*@type=C*/ v5 = super /*@target=Base::[]=*/ [
        /*@typeArgs=dynamic*/ f()] &= /*@typeArgs=dynamic*/ f();
    var /*@type=B*/ v6 =
        --super /*@target=Base::[]=*/ [/*@typeArgs=dynamic*/ f()];
    var /*@type=B*/ v7 =
        super /*@target=Base::[]=*/ [/*@typeArgs=dynamic*/ f()]--;
  }
}

main() {}
