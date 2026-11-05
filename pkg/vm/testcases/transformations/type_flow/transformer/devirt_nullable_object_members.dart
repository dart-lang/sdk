// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {}

class B extends A {}

class C extends A {
  @override
  String toString() => 'C';
}

void testNullableObjectMembers(B? b) {
  b.runtimeType;
  b.toString();
  b.hashCode;
  b == b;
}

void testNonNullableObjectMembers(B b) {
  b.runtimeType;
  b.toString();
  b.hashCode;
  b == b;
}

void testNullableOverriddenObjectMembers(C? c) {
  c.toString();
}

void testNonNullableOverriddenObjectMembers(C c) {
  c.toString();
}

void main() {
  testNullableObjectMembers(B());
  testNullableObjectMembers(null);
  testNonNullableObjectMembers(B());
  testNullableOverriddenObjectMembers(C());
  testNullableOverriddenObjectMembers(null);
  testNonNullableOverriddenObjectMembers(C());
}
