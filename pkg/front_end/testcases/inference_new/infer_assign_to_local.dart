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

void test(B local, B? local2, B? local3) {
  local = f();

  local2 ??= f();

  local += f();

  local *= f();

  local &= f();

  --local;

  local--;

  var v1 = local = f();

  var v2 = local3 ??= f();

  var v3 = local += f();

  var v4 = local *= f();

  var v5 = local &= f();

  var v6 = --local;

  var v7 = local--;
}

main() {}
