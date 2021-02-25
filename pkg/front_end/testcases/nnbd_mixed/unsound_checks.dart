// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.8

import 'unsound_checks_lib.dart';

isNullOptOut1(int i) => i == null;

isNotNullOptOut1(int i) => i != null;

isNullOptOut2(int i) => null == i;

isNotNullOptOut2(int i) => null != i;

ifNullOptOut(int i) => i ?? 42;

class OptOutClass1 {}

extension OptOutExtension on OptOutClass1 {
  int operator [](int index) => index;
  void operator []=(int index, int value) {}
}

extensionIfNullOptOut1(int i) => OptOutExtension(new OptOutClass1())[i] ??= 42;

extensionIfNullOptOut1ForEffect(int i) {
  OptOutExtension(new OptOutClass1())[i] ??= 42;
}

extensionIfNullOptOut2(int i) => new OptOutClass1()[i] ??= 42;

extensionIfNullOptOut2ForEffect(int i) {
  new OptOutClass1()[i] ??= 42;
}

class OptOutClass2 {
  int operator [](int index) => index;
  void operator []=(int index, int value) {}
}

ifNullIndexSetOptOut(int i) => new OptOutClass2()[i] ??= 42;

ifNullIndexSetOptOutForEffect(int i) {
  new OptOutClass2()[i] ??= 42;
}

class OptOutClass3 {
  int field;

  OptOutClass3(this.field);
}

ifNullPropertySetOptOut(int i) => new OptOutClass3(i).field ??= 42;

ifNullPropertySetOptOutForEffect(int i) {
  new OptOutClass3(i).field ??= 42;
}

ifNullSetOptOut(int i) => i ??= 42;

ifNullSetOptOutForEffect(int i) {
  i ??= 42;
}

class OptOutSuperClass4 {
  int operator [](int index) => index;
  void operator []=(int index, int value) {}
}

class OptOutClass4 extends OptOutSuperClass4 {
  method(int i) => super[i] ??= 42;
  methodForEffect(int i) {
    super[i] ??= 42;
  }
}

ifNullSuperIndexSetOptOut(int i) => new OptOutClass4().method(i);

ifNullSuperIndexSetOptOutForEffect(int i) {
  new OptOutClass4().methodForEffect(i);
}

class OptOutClass5 {
  int field;

  OptOutClass5(this.field);
}

nullAwareIfNullSetOptOut(int i) {
  OptOutClass5 o = new OptOutClass5(i);
  return o?.field ??= 42;
}

nullAwareIfNullSetOptOutForEffect(int i) {
  OptOutClass5 o = new OptOutClass5(i);
  o?.field ??= 42;
}

isTestOptOut(int i) => i is int;

isNotTestOptOut(int i) => i is! int;

main() {
  expect(false, isNullOptIn1(0));
  expect(false, isNullOptOut1(0));

  expect(true, isNullOptIn1(null));
  expect(true, isNullOptOut1(null));

  expect(true, isNotNullOptIn1(0));
  expect(true, isNotNullOptOut1(0));

  expect(false, isNotNullOptIn1(null));
  expect(false, isNotNullOptOut1(null));

  expect(false, isNullOptIn2(0));
  expect(false, isNullOptOut2(0));

  expect(true, isNullOptIn2(null));
  expect(true, isNullOptOut2(null));

  expect(true, isNotNullOptIn2(0));
  expect(true, isNotNullOptOut2(0));

  expect(false, isNotNullOptIn2(null));
  expect(false, isNotNullOptOut2(null));

  expect(0, ifNullOptIn(0));
  expect(0, ifNullOptOut(0));

  expect(42, ifNullOptIn(null));
  expect(42, ifNullOptOut(null));

  expect(0, extensionIfNullOptIn1(0));
  expect(0, extensionIfNullOptOut1(0));

  expect(42, extensionIfNullOptIn1(null));
  expect(42, extensionIfNullOptOut1(null));

  extensionIfNullOptIn1ForEffect(0);
  extensionIfNullOptOut1ForEffect(0);

  extensionIfNullOptIn1ForEffect(null);
  extensionIfNullOptOut1ForEffect(null);

  expect(0, extensionIfNullOptIn2(0));
  expect(0, extensionIfNullOptOut2(0));

  expect(42, extensionIfNullOptIn2(null));
  expect(42, extensionIfNullOptOut2(null));

  extensionIfNullOptIn2ForEffect(0);
  extensionIfNullOptOut2ForEffect(0);

  extensionIfNullOptIn2ForEffect(null);
  extensionIfNullOptOut2ForEffect(null);

  expect(0, ifNullIndexSetOptIn(0));
  expect(0, ifNullIndexSetOptOut(0));

  expect(42, ifNullIndexSetOptIn(null));
  expect(42, ifNullIndexSetOptOut(null));

  ifNullIndexSetOptInForEffect(0);
  ifNullIndexSetOptOutForEffect(0);

  ifNullIndexSetOptInForEffect(null);
  ifNullIndexSetOptOutForEffect(null);

  expect(0, ifNullPropertySetOptIn(0));
  expect(0, ifNullPropertySetOptOut(0));

  expect(42, ifNullPropertySetOptIn(null));
  expect(42, ifNullPropertySetOptOut(null));

  ifNullPropertySetOptInForEffect(0);
  ifNullPropertySetOptOutForEffect(0);

  ifNullPropertySetOptInForEffect(null);
  ifNullPropertySetOptOutForEffect(null);

  expect(0, ifNullSetOptIn(0));
  expect(0, ifNullSetOptOut(0));

  expect(42, ifNullSetOptIn(null));
  expect(42, ifNullSetOptOut(null));

  ifNullSetOptInForEffect(0);
  ifNullSetOptOutForEffect(0);

  ifNullSetOptInForEffect(null);
  ifNullSetOptOutForEffect(null);

  expect(0, ifNullSuperIndexSetOptIn(0));
  expect(0, ifNullSuperIndexSetOptOut(0));

  expect(42, ifNullSuperIndexSetOptIn(null));
  expect(42, ifNullSuperIndexSetOptOut(null));

  ifNullSuperIndexSetOptInForEffect(0);
  ifNullSuperIndexSetOptOutForEffect(0);

  ifNullSuperIndexSetOptInForEffect(null);
  ifNullSuperIndexSetOptOutForEffect(null);

  expect(0, nullAwareIfNullSetOptIn(0));
  expect(0, nullAwareIfNullSetOptOut(0));

  expect(42, nullAwareIfNullSetOptIn(null));
  expect(42, nullAwareIfNullSetOptOut(null));

  nullAwareIfNullSetOptInForEffect(0);
  nullAwareIfNullSetOptOutForEffect(0);

  nullAwareIfNullSetOptInForEffect(null);
  nullAwareIfNullSetOptOutForEffect(null);

  expect(true, isTestOptIn(0));
  expect(true, isTestOptOut(0));

  expect(false, isTestOptIn(null));
  expect(false, isTestOptOut(null));

  expect(false, isNotTestOptIn(0));
  expect(false, isNotTestOptOut(0));

  expect(true, isNotTestOptIn(null));
  expect(true, isNotTestOptOut(null));

  expect(true, nullAwareAccess1(0));
  expect(null, nullAwareAccess1(null));

  promotionToNever(0);
  promotionToNever(null);

  unnecessaryNullCheck(() => 0);
  unnecessaryNullCheck(() => null);

  expect(0, unnecessaryIfNull(() => 0, () => 42));
  expect(42, unnecessaryIfNull(() => null, () => 42));

  unnecessaryIfNullAssign(<int>[0], () => 42);
  unnecessaryIfNullAssign(<int>[null], () => 42);

  unnecessaryNullAwareAccess(() => 0);
  unnecessaryNullAwareAccess(() => null);

  throws(() => callReturningNever(() => throw 'foo'), (e) => e == 'foo');
  var f = () => null;
  throws(() => callReturningNever(f));

  switchOnEnum(E.e1);
  switchOnEnum(E.e2);
  throws(() => switchOnEnum(null));

  switchOnEnumWithBreak(E.e1);
  switchOnEnumWithBreak(E.e2);
  throws(() => switchOnEnumWithBreak(null));

  switchOnEnumWithFallThrough1(E.e1);
  switchOnEnumWithFallThrough1(E.e2);
  throws(() => switchOnEnumWithFallThrough1(null));

  switchOnEnumWithFallThrough2(E.e1);
  switchOnEnumWithFallThrough2(E.e2);
  throws(() => switchOnEnumWithFallThrough2(null));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(void f(), [bool Function(Object) testException]) {
  try {
    f();
  } catch (e) {
    if (testException != null && !testException(e)) {
      throw 'Unexpected exception: $e';
    }
    print(e);
    return;
  }
  throw 'Missing exception.';
}
