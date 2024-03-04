// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

// Use a helper for `Expect.isTrue` and `Expect.isFalse` as those methods don't
// differentiate between `JSBoolean` and `bool`.
void expectTrue(bool value) {
  Expect.isTrue(value);
}

void expectFalse(bool value) {
  Expect.isFalse(value);
}

int toInt(JSAny any) => (any as JSNumber).toDartInt;

void dartJsInteropOperatorsTest() {
  // Arithmetic.
  final i10 = 10.toJS;
  expect(toInt(i10.add(1.toJS)), 11);
  expect(toInt(i10.subtract(1.toJS)), 9);
  expect(toInt(i10.multiply(2.toJS)), 20);
  expect(toInt(i10.divide(10.toJS)), 1);
  expect(toInt(i10.modulo(5.toJS)), 0);
  expect(toInt(i10.exponentiate(2.toJS)), 100);

  // Bitwise.
  expect(toInt(i10.unsignedRightShift(1.toJS)), 5);

  // Comparison/relational.
  final t = true.toJS;
  final f = false.toJS;
  // Equality attempts to coerce, whereas strict equality does not.
  expectTrue(t.equals(1.toJS));
  expectFalse(t.notEquals(1.toJS));
  expectFalse(t.strictEquals(1.toJS));
  expectTrue(t.strictNotEquals(1.toJS));
  expectFalse((t.and(f) as JSBoolean).toDart);
  expectTrue((t.or(f) as JSBoolean).toDart);
  expectFalse(t.not);
  expectTrue(t.isTruthy);
  expectFalse(i10.lessThan(i10));
  expectTrue(i10.lessThanOrEqualTo(i10));
  expectFalse(i10.greaterThan(i10));
  expectTrue(i10.greaterThanOrEqualTo(i10));

  // Nulls.
  expect(toInt(null.add(null)), 0);
  expect(toInt(null.subtract(null)), 0);
  expect(toInt(null.multiply(null)), 0);
  expectTrue(isNaN(null.divide(null)));
  expectTrue(isNaN(null.modulo(null)));
  expect(toInt(null.exponentiate(null)), 1);
  expect(toInt(null.unsignedRightShift(null)), 0);
  expectTrue(null.equals(null));
  expectFalse(null.notEquals(null));
  expectTrue(null.strictEquals(null));
  expectFalse(null.strictNotEquals(null));
  expect(null.and(null), null);
  expect(null.or(null), null);
  expectTrue(null.not);
  expectFalse(null.isTruthy);
  expectFalse(null.lessThan(null));
  expectTrue(null.lessThanOrEqualTo(null));
  expectFalse(null.greaterThan(null));
  expectTrue(null.greaterThanOrEqualTo(null));

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
  expect(toInt(t.unsignedRightShift(f)), 1);
  final b1 = 1.toBigInt;
  expectTrue(b1.equals(t));
  expectFalse(b1.notEquals(t));
  expectFalse(b1.strictEquals(t));
  expectTrue(b1.strictNotEquals(t));
  expect(b10.and(b1), b1);
  expect(b10.or(b1), b10);
  expectFalse(b10.not);
  expectTrue(b10.isTruthy);
  expectFalse(b10.lessThan(b10));
  expectTrue(b10.lessThanOrEqualTo(b10));
  expectFalse(b10.greaterThan(b10));
  expectTrue(b10.greaterThanOrEqualTo(b10));
}

void main() {
  extensionTypeTest();
  staticInteropTest();
  dartJsInteropOperatorsTest();
}
