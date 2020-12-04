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

  static int get staticGetterSetter => staticField;

  static set staticGetterSetter(int? value) {}

  int instanceField;

  int get instanceGetterSetter => instanceField;

  set instanceGetterSetter(int? value) {}

  int operator [](int index) => instanceField;

  operator []=(int index, int? value) {}

  static late String error;

  get throwingGetter => throw 'Null access';

  C(this.instanceField);
}

class D extends C {
  D(int field) : super(field);

  int ifNullAssignSuper(int f()) {
    return super.instanceField ??= f(); // ignore: dead_null_aware_expression
  }

  int ifNullAssignSuper_nullableSetter(int f()) {
    return super.instanceGetterSetter ??=
        f(); // ignore: dead_null_aware_expression
  }

  int ifNullAssignSuperIndex(int f()) {
    return super[0] ??= f(); // ignore: dead_null_aware_expression
  }
}

class E {
  int instanceField;

  E(this.instanceField);
}

extension EExt on E {
  int get instanceGetterSetter => instanceField;

  set instanceGetterSetter(int? value) {}

  int operator [](int index) => instanceField;

  operator []=(int index, int? value) {}
}

extension IntQExt on int? {
  int extendedMethod(int value) => value;

  int get extendedGetter => 0;
}

class NeverField {
  late Never n;

  NeverField();
  NeverField.initializingFormal(this.n);
}

enum Hand { left, right }

late Never topLevelNever;

int neverParameter(Never n) {
  return 42;
}

int neverInitializingFormal(Never n) {
  return 42;
}

bool isPromoteToNever(int i) {
  if (i is int) return true;
  return false;
}

bool isPromoteToNever_noIf(int i) {
  return i is int;
}

bool isNotPromoteToNever(int i) {
  if (i is! int) {
    return true;
  }
  return false;
}

bool isNotPromoteToNever_noIf(int i) {
  return i is! int;
}

int equalNullPromoteToNever(int f()) {
  if (f() == null) {
    // ignore: unnecessary_null_comparison
    return 42;
  }
  return 0;
}

int equalNullPromoteToNever_noIf(int f()) {
  f() == null; // ignore: unnecessary_null_comparison
  return 42;
}

int notEqualNullPromoteToNever(int f()) {
  if (f() != null) return 0; // ignore: unnecessary_null_comparison
  return 42;
}

int notEqualNullPromoteToNever_noIf(int f()) {
  f() != null; // ignore: unnecessary_null_comparison
  return 42;
}

int nullEqualPromoteToNever(int f()) {
  if (null == f()) {
    // ignore: unnecessary_null_comparison
    return 42;
  }
  return 0;
}

int nullEqualPromoteToNever_noIf(int f()) {
  null == f(); // ignore: unnecessary_null_comparison
  return 42;
}

int nullNotEqualPromoteToNever(int f()) {
  if (null != f()) return 0; // ignore: unnecessary_null_comparison
  return 42;
}

int nullNotEqualPromoteToNever_noIf(int f()) {
  null != f(); // ignore: unnecessary_null_comparison
  return 42;
}

int unnecessaryIfNull(int f(), int g()) {
  return f() ?? g(); // ignore: dead_null_aware_expression
}

int ifNullAssignLocal(int local, int f()) {
  return local ??= f(); // ignore: dead_null_aware_expression
}

int ifNullAssignStatic(int f()) {
  return C.staticField ??= f(); // ignore: dead_null_aware_expression
}

int ifNullAssignStaticGetter_nullableSetter(int f()) {
  return C.staticGetterSetter ??= f(); // ignore: dead_null_aware_expression
}

int ifNullAssignField(C c, int f()) {
  return c.instanceField ??= f(); // ignore: dead_null_aware_expression
}

int ifNullAssignGetter_nullableSetter(C c, int f()) {
  return c.instanceGetterSetter ??= f(); // ignore: dead_null_aware_expression
}

int ifNullAssignGetter_implicitExtension(E e, int f()) {
  return e.instanceGetterSetter ??= f(); // ignore: dead_null_aware_expression
}

int ifNullAssignGetter_explicitExtension(E e, int f()) {
  return EExt(e).instanceGetterSetter ??=
      f(); // ignore: dead_null_aware_expression
}

int ifNullAssignIndex(List<int> x, int f()) {
  return x[0] ??= f(); // ignore: dead_null_aware_expression
}

int? ifNullAssignIndex_nullAware(List<int>? x, int f()) {
  return x?[0] ??= f(); // ignore: dead_null_aware_expression
}

int ifNullAssignIndex_nullableSetter(C x, int f()) {
  return x[0] ??= f(); // ignore: dead_null_aware_expression
}

int ifNullAssignIndex_implicitExtension(E x, int f()) {
  return x[0] ??= f(); // ignore: dead_null_aware_expression
}

int ifNullAssignIndex_explicitExtension(E x, int f()) {
  return EExt(x)[0] ??= f(); // ignore: dead_null_aware_expression
}

int ifNullAssignSuper(D d, int f()) {
  return d.ifNullAssignSuper(f);
}

int ifNullAssignSuper_nullableSetter(D d, int f()) {
  return d.ifNullAssignSuper_nullableSetter(f);
}

int ifNullAssignSuperIndex(D d, int f()) {
  return d.ifNullAssignSuperIndex(f);
}

int? ifNullAssignNullAwareField(C? c, int f()) {
  return c?.instanceField ??= f(); // ignore: dead_null_aware_expression
}

int ifNullAssignNullAwareStatic(int f()) {
  return C?.staticField ??= f(); // ignore: dead_null_aware_expression
}

void unnecessaryNullAwareAccess(int f()) {
  f()?.gcd(throw 'Null access'); // ignore: invalid_null_aware_operator
}

void unnecessaryNullAwareAccess_cascaded(int f()) {
  f()?..gcd(throw 'Null access'); // ignore: invalid_null_aware_operator
}

void unnecessaryNullAwareAccess_methodOnObject(int f()) {
  // ignore: invalid_null_aware_operator
  f()?.toString().compareTo(throw 'Null access');
}

void unnecessaryNullAwareAccess_cascaded_methodOnObject(int f()) {
  // ignore: invalid_null_aware_operator
  f()?..toString().compareTo(throw 'Null access');
}

void unnecessaryNullAwareAccess_methodOnExtension(int f()) {
  // ignore: invalid_null_aware_operator
  f()?.extendedMethod(throw 'Null access');
}

void unnecessaryNullAwareAccess_cascaded_methodOnExtension(int f()) {
  // ignore: invalid_null_aware_operator
  f()?..extendedMethod(throw 'Null access');
}

void unnecessaryNullAwareAccess_methodOnExtension_explicit(int f()) {
  // ignore: invalid_null_aware_operator
  IntQExt(f())?.extendedMethod(throw 'Null access');
}

void unnecessaryNullAwareAccess_getter(C f()) {
  f()?.throwingGetter; // ignore: invalid_null_aware_operator
}

void unnecessaryNullAwareAccess_cascaded_getter(C f()) {
  f()?..throwingGetter; // ignore: invalid_null_aware_operator
}

void unnecessaryNullAwareAccess_getterOnObject(int f()) {
  // ignore: invalid_null_aware_operator
  f()?.hashCode.remainder(throw 'Null access');
}

void unnecessaryNullAwareAccess_cascaded_getterOnObject(int f()) {
// ignore: invalid_null_aware_operator
  f()?..hashCode.remainder(throw 'Null access');
}

void unnecessaryNullAwareAccess_getterOnExtension(int f()) {
  // ignore: invalid_null_aware_operator
  f()?.extendedGetter.remainder(throw 'Null access');
}

void unnecessaryNullAwareAccess_cascaded_getterOnExtension(int f()) {
  // ignore: invalid_null_aware_operator
  f()?..extendedGetter.remainder(throw 'Null access');
}

void unnecessaryNullAwareAccess_getterOnExtension_explicit(int f()) {
  // ignore: invalid_null_aware_operator
  IntQExt(f())?.extendedGetter.remainder(throw 'Null access');
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

int switchOnBool(bool b) {
  switch (b) {
    case true:
      return 0;
    case false:
      return 1;
  }
  return 42;
}

void switchOnEnum(Hand hand) {
  switch (hand) {
    case Hand.left:
      return;
    case Hand.right:
      return;
  }
  // Should throw if the implicit `default` branch is taken.
}
