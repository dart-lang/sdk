// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

// Test operators through overloading and the ones defined in dart:js_interop.

@JS()
library operator_test;

import 'dart:js_interop';

import 'package:expect/expect.dart';
import 'package:expect/minitest.dart';

@JS()
extension type OperableExtType(JSObject _) {
  external int operator [](int index);
  external void operator []=(int index, int value);
}

void extensionTypeTest() {
  final obj = OperableExtType(JSObject());
  obj[4] = 5;
  expect(obj[4], 5);

  final arr = OperableExtType(JSArray());
  arr[6] = 7;
  expect(arr[6], 7);
}

@JS()
@staticInterop
class Operable {}

extension OperableExtension on Operable {
  external int operator [](int index);
  external void operator []=(int index, int value);
}

void staticInteropTest() {
  final obj = JSObject() as Operable;
  obj[4] = 5;
  expect(obj[4], 5);

  final arr = JSArray() as Operable;
  arr[5] = 6;
  expect(arr[5], 6);
}

@JS()
external bool isNaN(JSAny? number);

@JS()
external JSBigInt BigInt(String value);

extension on int {
  JSBigInt get toBigInt => BigInt(this.toString());
}

void dartJsInteropOperatorsTest() {
  // Arithmetic.
  final i10 = 10.toJS;
  expect(i10.add(1.toJS), 11.toJS);
  expect(i10.subtract(1.toJS), 9.toJS);
  expect(i10.multiply(2.toJS), 20.toJS);
  expect(i10.divide(10.toJS), 1.toJS);
  expect(i10.modulo(5.toJS), 0.toJS);
  expect(i10.exponentiate(2.toJS), 100.toJS);

  // Bitwise.
  expect(i10.unsignedRightShift(1.toJS), 5.toJS);

  // Comparison/relational.
  final t = true.toJS;
  final f = false.toJS;
  // Equality attempts to coerce, whereas strict equality does not.
  Expect.isTrue(t.equals(1.toJS));
  Expect.isFalse(t.notEquals(1.toJS));
  Expect.isFalse(t.strictEquals(1.toJS));
  Expect.isTrue(t.strictNotEquals(1.toJS));
  Expect.isFalse((t.and(f) as JSBoolean).toDart);
  Expect.isTrue((t.or(f) as JSBoolean).toDart);
  Expect.isFalse(t.not);
  Expect.isTrue(t.isTruthy);
  Expect.isFalse(i10.lessThan(i10));
  Expect.isTrue(i10.lessThanOrEqualTo(i10));
  Expect.isFalse(i10.greaterThan(i10));
  Expect.isTrue(i10.greaterThanOrEqualTo(i10));

  // Nulls.
  expect(null.add(null), 0.toJS);
  expect(null.subtract(null), 0.toJS);
  expect(null.multiply(null), 0.toJS);
  Expect.isTrue(isNaN(null.divide(null)));
  Expect.isTrue(isNaN(null.modulo(null)));
  expect(null.exponentiate(null), 1.toJS);
  expect(null.unsignedRightShift(null), 0.toJS);
  Expect.isTrue(null.equals(null));
  Expect.isFalse(null.notEquals(null));
  Expect.isTrue(null.strictEquals(null));
  Expect.isFalse(null.strictNotEquals(null));
  expect(null.and(null), null);
  expect(null.or(null), null);
  Expect.isTrue(null.not);
  Expect.isFalse(null.isTruthy);
  Expect.isFalse(null.lessThan(null));
  Expect.isTrue(null.lessThanOrEqualTo(null));
  Expect.isFalse(null.greaterThan(null));
  Expect.isTrue(null.greaterThanOrEqualTo(null));

  // Different types.
  final b10 = 10.toBigInt;
  expect(b10.add(1.toBigInt), 11.toBigInt);
  expect(b10.subtract(1.toBigInt), 9.toBigInt);
  expect(b10.multiply(2.toBigInt), 20.toBigInt);
  expect(b10.divide(10.toBigInt), 1.toBigInt);
  expect(b10.modulo(5.toBigInt), 0.toBigInt);
  expect(b10.exponentiate(2.toBigInt), 100.toBigInt);
  // Note that `unsignedRightShift` can not be used with BigInts and always
  // returns a number.
  expect(t.unsignedRightShift(f), 1.toJS);
  final b1 = 1.toBigInt;
  Expect.isTrue(b1.equals(t));
  Expect.isFalse(b1.notEquals(t));
  Expect.isFalse(b1.strictEquals(t));
  Expect.isTrue(b1.strictNotEquals(t));
  expect(b10.and(b1), b1);
  expect(b10.or(b1), b10);
  Expect.isFalse(b10.not);
  Expect.isTrue(b10.isTruthy);
  Expect.isFalse(b10.lessThan(b10));
  Expect.isTrue(b10.lessThanOrEqualTo(b10));
  Expect.isFalse(b10.greaterThan(b10));
  Expect.isTrue(b10.greaterThanOrEqualTo(b10));
}

void main() {
  extensionTypeTest();
  staticInteropTest();
  dartJsInteropOperatorsTest();
}
