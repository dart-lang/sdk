// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

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
  B member = throw '';
  B? member2;

  static void test(Test? t) {
    t?.member = f();

    t?.member2 ??= f();

    t?.member += f();

    t?.member *= f();

    t?.member &= f();

    --t?.member;

    t?.member--;

    var v1 = t?.member = f();

    var v2 = t?.member2 ??= f();

    var v3 = t?.member += f();

    var v4 = t?.member *= f();

    var v5 = t?.member &= f();

    var v6 = --t?.member;

    var v7 = t?.member--;
  }
}

main() {}
