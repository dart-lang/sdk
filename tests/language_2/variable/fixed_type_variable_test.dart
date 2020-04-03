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

  void test(var type, bool expect) {
    Expect.equals(expect, T == type);
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
  instanceB.test(num, false);
  instanceB.test(int, false);
  instanceB.test(String, true);
}

void testNumA() {
  var instanceA = new NumA();
  var instanceB = instanceA.createB();
  instanceB.test(num, true);
  instanceB.test(int, false);
  instanceB.test(String, false);
}

void testB() {
  var instanceB = new B<int>();
  instanceB.test(num, false);
  instanceB.test(int, true);
  instanceB.test(String, false);
}

void testStringB() {
  var instanceB = new StringB();
  instanceB.test(num, false);
  instanceB.test(int, false);
  instanceB.test(String, true);
}

void testC() {
  var instanceA = new C<String>();
  var instanceB = instanceA.createB();
  instanceB.test(num, false);
  instanceB.test(int, false);
  instanceB.test(String, true);
}

void testIntC() {
  var instanceA = new IntC();
  var instanceB = instanceA.createB();
  instanceB.test(num, false);
  instanceB.test(int, true);
  instanceB.test(String, false);
}
