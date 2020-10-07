// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

isNullOptIn1(int i) => i == null;

isNotNullOptIn1(int i) => i != null;

isNullOptIn2(int i) => null == i;

isNotNullOptIn2(int i) => null != i;

ifNullOptIn(int i) => i ?? 42;

class OptInClass1 {}

extension OptInExtension on OptInClass1 {
  int operator [](int index) => index;
  void operator []=(int index, int value) {}
}

extensionIfNullOptIn1(int i) => OptInExtension(new OptInClass1())[i] ??= 42;

extensionIfNullOptIn1ForEffect(int i) {
  OptInExtension(new OptInClass1())[i] ??= 42;
}

extensionIfNullOptIn2(int i) => new OptInClass1()[i] ??= 42;

extensionIfNullOptIn2ForEffect(int i) {
  new OptInClass1()[i] ??= 42;
}

class OptInClass2 {
  int operator [](int index) => index;
  void operator []=(int index, int value) {}
}

ifNullIndexSetOptIn(int i) => new OptInClass2()[i] ??= 42;

ifNullIndexSetOptInForEffect(int i) {
  new OptInClass2()[i] ??= 42;
}

class OptInClass3 {
  int field;

  OptInClass3(this.field);
}

ifNullPropertySetOptIn(int i) => new OptInClass3(i).field ??= 42;

ifNullPropertySetOptInForEffect(int i) {
  new OptInClass3(i).field ??= 42;
}

ifNullSetOptIn(int i) => i ??= 42;

ifNullSetOptInForEffect(int i) {
  i ??= 42;
}

class OptInSuperClass4 {
  int operator [](int index) => index;
  void operator []=(int index, int value) {}
}

class OptInClass4 extends OptInSuperClass4 {
  method(int i) => super[i] ??= 42;
  methodForEffect(int i) {
    super[i] ??= 42;
  }
}

ifNullSuperIndexSetOptIn(int i) => new OptInClass4().method(i);

ifNullSuperIndexSetOptInForEffect(int i) {
  new OptInClass4().methodForEffect(i);
}

class OptInClass5 {
  int field;

  OptInClass5(this.field);
}

nullAwareIfNullSetOptIn(int i) {
  OptInClass5? o = new OptInClass5(i) as OptInClass5?;
  return o?.field ??= 42;
}

nullAwareIfNullSetOptInForEffect(int i) {
  OptInClass5? o = new OptInClass5(i) as OptInClass5?;
  o?.field ??= 42;
}

isTestOptIn(int i) => i is int;

isNotTestOptIn(int i) => i is! int;

class OptInClass6a {
  final OptInClass6b cls;

  OptInClass6a(this.cls);
}

class OptInClass6b {
  final int field;

  OptInClass6b(this.field);
}

nullAwareAccess1(int i) => i?.isEven;

nullAwareAccessForEffect1(int i) {
  i?.isEven;
}

promotionToNever(int i) {
  if (i is int) return; // Should not throw if `i` is null
}

unnecessaryNullCheck(int f()) {
  if (f() != null) return; // Should not throw if `f` returns null
}

unnecessaryIfNull(int f(), int g()) {
  return f() ??
      g(); // Should not throw if `f` returns null (rather than calling `g`)
}

unnecessaryIfNullAssign(List<int> x, int f()) {
  // Should not  throw if `x[0]` returns null (rather than calling `f`)
  x[0] ??= f();
}

unnecessaryNullAwareAccess(int f()) {
  f()?.gcd(0); // Should not throw if `f` returns null
}

callReturningNever(Never f()) {
  f(); // Should throw if `f` completes normally
}

enum E { e1, e2 }

switchOnEnum(E e) {
  switch (e) {
    case E.e1:
      return;
    case E.e2:
      return;
  } // Should throw if the implicit `default` branch is taken
}

switchOnEnumWithBreak(E e) {
  switch (e) {
    case E.e1:
      break;
    case E.e2:
      break;
  } // Should throw if the implicit `default` branch is taken
}

switchOnEnumWithFallThrough1(E e) {
  switch (e) {
    case E.e1:
      break;
    case E.e2:
  } // Should throw if the implicit `default` branch is taken
}

switchOnEnumWithFallThrough2(E e) {
  switch (e) {
    case E.e1:
    case E.e2:
  } // Should throw if the implicit `default` branch is taken
}

handleThrow() {
  throw ''; // Should not throw ReachabilityError.
}

handleRethrow() {
  try {
    handleThrow();
  } catch (_) {
    rethrow; // Should not throw ReachabilityError.
  }
}

handleInvalid(dynamic d) {
  // This is deliberately creating a compile-time error to verify that we
  // don't create ReachabilityError for invalid expressions.
  return {...d}; // Should not throw ReachabilityError.
}
