// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type variables are passed on from subtypes that fixed the type
// variable in inheritance.

import 'package:expect/expect.dart';

class A<T> {
  B<T> createB() => new B<T>();
}

class NumA extends A<num> {}

class B<T> {
  T value;

  void test(var o, bool expect) {
    Expect.equals(expect, o is T);
  }
}

class StringB extends B<String> {}

class C<T> extends A<T> {}

class IntC extends C<int> {}

void main() {
  testA(); //# 01: ok
  testNumA(); //# 02: ok
  testB(); //# 03: ok
  testStringB(); //# 04: ok
  testC(); //# 05: ok
  testIntC(); //# 06: ok
}

void testA() {
  var instanceA = new A<String>();
  var instanceB = instanceA.createB();
  instanceB.test(0.5, false);
  instanceB.test(0, false);
  instanceB.test('', true);
}

void testNumA() {
  var instanceA = new NumA();
  var instanceB = instanceA.createB();
  instanceB.test(0.5, true);
  instanceB.test(0, true);
  instanceB.test('', false);
}

void testB() {
  var instanceB = new B<int>();
  instanceB.test(0.5, false);
  instanceB.test(0, true);
  instanceB.test('', false);
}

void testStringB() {
  var instanceB = new StringB();
  instanceB.test(0.5, false);
  instanceB.test(0, false);
  instanceB.test('', true);
}

void testC() {
  var instanceA = new C<String>();
  var instanceB = instanceA.createB();
  instanceB.test(0.5, false);
  instanceB.test(0, false);
  instanceB.test('', true);
}

void testIntC() {
  var instanceA = new IntC();
  var instanceB = instanceA.createB();
  instanceB.test(0.5, false);
  instanceB.test(0, true);
  instanceB.test('', false);
}
