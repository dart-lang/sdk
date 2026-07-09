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
    Test t = f();

    t[f()] = f();

    t[f()] += f();

    t[f()] *= f();

    t[f()] &= f();

    t[f()];

    --t[f()];

    t[f()]--;

    var v1 = t[f()] = f();

    var v3 = t[f()] += f();

    var v4 = t[f()] *= f();

    var v5 = t[f()] &= f();

    var v6 = t[f()];

    var v7 = --t[f()];

    var v8 = t[f()]--;
  }
}

class Test2 {
  B? operator [](Index i) => throw '';
  void operator []=(Index i, B? v) {}

  void test() {
    Test2 t = f();

    t[f()] = f();

    t[f()] ??= f();

    var v2 = t[f()] ??= f();
  }
}

main() {}
