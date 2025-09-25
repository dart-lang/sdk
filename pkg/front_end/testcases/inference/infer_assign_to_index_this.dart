// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    this[f()] = f();

    this[f()] += f();

    this[f()] *= f();

    this[f()] &= f();

    --this[f()];

    this[f()]--;

    var v1 = this[f()] = f();

    var v4 = this[f()] += f();

    var v3 = this[f()] *= f();

    var v5 = this[f()] &= f();

    var v6 = --this[f()];

    var v7 = this[f()]--;
  }
}

class Test2 {
  B? operator [](Index i) => throw '';
  void operator []=(Index i, B? v) {}

  void test() {
    this[f()] ??= f();

    var v2 = this[f()] ??= f();
  }
}

main() {}
