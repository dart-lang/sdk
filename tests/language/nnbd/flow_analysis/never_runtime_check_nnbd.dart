// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  Never get getter;
  Never method();
  Never operator +(int other);
  Never operator [](int other);
}

class C {
  static int staticField = 0;

  int instanceField;

  C(this.instanceField);
}

class D extends C {
  D(int field) : super(field);

  void ifNullAssignSuper(int f()) {
    super.instanceField ??= f(); // ignore: dead_null_aware_expression
    // Should throw if `instanceField` returns null (rather than calling `f`).
  }
}

class NeverField {
  late Never n;

  NeverField();
  NeverField.initializingFormal(this.n);
}

enum Hand { left, right }

late Never topLevelNever;

void neverParameter(Never n) {
  // Should throw before getting here.
}

void neverInitializingFormal(Never n) {
  // Should throw before getting here.
}

void isPromoteToNever(int i) {
  if (i is int) return;
  // Should throw if `i` is null.
}

void isNotPromoteToNever(int i) {
  if (i is! int) {
    // Should throw if `i` is null.
  }
}

void equalNullPromoteToNever(int f()) {
  if (f() == null) { // ignore: unnecessary_null_comparison
    // Should throw if `f` returns null.
  }
}

void notEqualNullPromoteToNever(int f()) {
  if (f() != null) return; // ignore: unnecessary_null_comparison
  // Should throw if `f` returns null.
}

void nullEqualPromoteToNever(int f()) {
  if (null == f()) { // ignore: unnecessary_null_comparison
    // Should throw if `f` returns null.
  }
}

void nullNotEqualPromoteToNever(int f()) {
  if (null != f()) return; // ignore: unnecessary_null_comparison
  // Should throw if `f` returns null.
}

int unnecessaryIfNull(int f(), int g()) {
  return f() ?? g(); // ignore: dead_null_aware_expression
  // Should throw if `f` returns null (rather than calling `g`).
}

void ifNullAssignLocal(int local, int f()) {
  local ??= f(); // ignore: dead_null_aware_expression
  // Should throw if `local` returns null (rather than calling `f`).
}

void ifNullAssignStatic(int f()) {
  C.staticField ??= f(); // ignore: dead_null_aware_expression
  // Should throw if `staticField` returns null (rather than calling `f`).
}

void ifNullAssignField(C c, int f()) {
  c.instanceField ??= f(); // ignore: dead_null_aware_expression
  // Should throw if `instanceField` returns null (rather than calling `f`).
}

void ifNullAssignIndex(List<int> x, int f()) {
  x[0] ??= f(); // ignore: dead_null_aware_expression
  // Should throw if `x[0]` returns null (rather than calling `f`).
}

void ifNullAssignSuper(D d, int f()) {
  d.ifNullAssignSuper(f);
}

int? ifNullAssignNullAwareField(C? c, int f()) {
  return c?.instanceField ??= f(); // ignore: dead_null_aware_expression
  // Should throw if `instanceField` returns null (rather than calling `f`).
}

void ifNullAssignNullAwareStatic(int f()) {
  C?.staticField ??= f(); // ignore: dead_null_aware_expression
  // Should throw if `staticField` returns null (rather than calling `f`).
}

void unnecessaryNullAwareAccess(int f(), String error) {
  f()?.gcd(throw error); // ignore: invalid_null_aware_operator
  // Should throw if `f` returns null.
}

void getterReturnsNever(A a) {
  a.getter;
  // Should throw if `getter` completes normally.
}

void methodReturnsNever(A a) {
  a.method();
  // Should throw if `method` completes normally.
}

void operatorReturnsNever(A a) {
  a + 1;
  // Should throw if `+` completes normally.
}

void indexReturnsNever(A a) {
  a[0];
  // Should throw if `[]` completes normally.
}

void returnsNeverInExpression(A a) {
  List<Never> x = [a.method()];
  // Should throw if `method` completes normally.
}

void returnsNeverInVariable(A a) {
  Never x = a.method();
  // Should throw if `method` completes normally.
}


void switchOnBool(bool b) {
  switch (b) {
    case true: return;
    case false: return;
  }
  // Should throw if the implicit `default` branch is taken.
}

void switchOnEnum(Hand hand) {
  switch (hand) {
    case Hand.left: return;
    case Hand.right: return;
  }
  // Should throw if the implicit `default` branch is taken.
}