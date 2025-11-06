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

class Base {
  B member = throw '';
  B? member2;
}

class Test extends Base {
  void test() {
    super.member = f();

    super.member2 ??= f();

    super.member += f();

    super.member *= f();

    super.member &= f();

    --super.member;

    super.member--;

    var v1 = super.member = f();

    var v2 = super.member2 ??= f();

    var v3 = super.member += f();

    var v4 = super.member *= f();

    var v5 = super.member &= f();

    var v6 = --super.member;

    var v7 = super.member--;
  }
}

main() {}
