// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class Index {}

class A {
  C operator +(F v) => throw '';
  C operator -(int i) => throw '';
}

class B extends A {
  D operator +(E v) => throw '';
  D operator -(int i) => throw '';
}

class C extends B {}

class D extends C {}

class E extends D {}

class F extends E {}

T f<T>() => throw '';

class Test {
  B operator [](Index i) => throw '';
  void operator []=(Index i, A v) {}

  void test() {
    Test t = f();

    t[f()] = f();

    t[f()] += f();

    --t[f()];

    t[f()]--;

    var v1 = t[f()] = f();

    var v3 = t[f()] += f();

    var v4 = --t[f()];

    var v5 = t[f()]--;
  }
}

class Test2 {
  B? operator [](Index i) => throw '';
  void operator []=(Index i, A? v) {}

  void test() {
    Test2 t = f();

    t[f()] ??= f();

    var v2 = t[f()] ??= f();
  }
}

main() {}
