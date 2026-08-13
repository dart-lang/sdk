// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class A {}

class B extends A {
  A operator +(C v) => throw '';
  B operator -(int i) => throw '';
  B operator *(B v) => throw '';
  C operator &(A v) => throw '';
}

class C extends B {}

T f<T>() => throw '';

class Test {
  B member;
  B? member2;

  Test(this.member, this.member2);

  void test() {
    member = f();

    member2 ??= f();

    member += f();

    member *= f();

    member &= f();

    --member;

    member--;

    var v1 = member = f();

    var v2 = member2 ??= f();

    var v3 = member += f();

    var v4 = member *= f();

    var v5 = member &= f();

    var v6 = --member;

    var v7 = member--;
  }
}

main() {}
