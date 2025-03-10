// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test operators through overloading and the ones defined in dart:js_interop.

import 'dart:js_interop';

import 'package:expect/expect.dart';

@JS()
extension type OperableExtType(JSObject _) {
  external int operator [](int index);
  external void operator []=(int index, int value);
}

void extensionTypeTest() {
  final obj = OperableExtType(JSObject());
  obj[4] = 5;
  Expect.equals(5, obj[4]);

  final arr = OperableExtType(JSArray());
  arr[6] = 7;
  Expect.equals(7, arr[6]);
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
  Expect.equals(5, obj[4]);

  final arr = JSArray() as Operable;
  arr[5] = 6;
  Expect.equals(6, arr[5]);
}

@JS()
external bool isNaN(JSAny? number);

@JS()
external JSBigInt BigInt(String value);

extension on int {
  JSBigInt get toBigInt => BigInt(this.toString());
}

int toInt(JSAny any) => (any as JSNumber).toDartInt;

void dartJsInteropOperatorsTest() {
  // Arithmetic.
  final i10 = 10.toJS;
  Expect.equals(11, toInt(i10.add(1.toJS)));
  Expect.equals(9, toInt(i10.subtract(1.toJS)));
  Expect.equals(20, toInt(i10.multiply(2.toJS)));
  Expect.equals(1, toInt(i10.divide(10.toJS)));
  Expect.equals(0, toInt(i10.modulo(5.toJS)));
  Expect.equals(100, toInt(i10.exponentiate(2.toJS)));

  // Bitwise.
  Expect.equals(5, toInt(i10.unsignedRightShift(1.toJS)));

  // Comparison/relational.
  final t = true.toJS;
  final f = false.toJS;
  // Equality attempts to coerce, whereas strict equality does not.
  Expect.isTrue(t.equals(1.toJS).toDart);
  Expect.isFalse(t.notEquals(1.toJS).toDart);
  Expect.isFalse(t.strictEquals(1.toJS).toDart);
  Expect.isTrue(t.strictNotEquals(1.toJS).toDart);
  Expect.isFalse((t.and(f) as JSBoolean).toDart);
  Expect.isTrue((t.or(f) as JSBoolean).toDart);
  Expect.isFalse(t.not.toDart);
  Expect.isTrue(t.isTruthy.toDart);
  Expect.isFalse(i10.lessThan(i10).toDart);
  Expect.isTrue(i10.lessThanOrEqualTo(i10).toDart);
  Expect.isFalse(i10.greaterThan(i10).toDart);
  Expect.isTrue(i10.greaterThanOrEqualTo(i10).toDart);

  // Nulls.
  Expect.equals(0, toInt(null.add(null)));
  Expect.equals(0, toInt(null.subtract(null)));
  Expect.equals(0, toInt(null.multiply(null)));
  Expect.isTrue(isNaN(null.divide(null)));
  Expect.isTrue(isNaN(null.modulo(null)));
  Expect.equals(1, toInt(null.exponentiate(null)));
  Expect.equals(0, toInt(null.unsignedRightShift(null)));
  Expect.isTrue(null.equals(null).toDart);
  Expect.isFalse(null.notEquals(null).toDart);
  Expect.isTrue(null.strictEquals(null).toDart);
  Expect.isFalse(null.strictNotEquals(null).toDart);
  Expect.isNull(null.and(null));
  Expect.isNull(null.or(null));
  Expect.isTrue(null.not.toDart);
  Expect.isFalse(null.isTruthy.toDart);
  Expect.isFalse(null.lessThan(null).toDart);
  Expect.isTrue(null.lessThanOrEqualTo(null).toDart);
  Expect.isFalse(null.greaterThan(null).toDart);
  Expect.isTrue(null.greaterThanOrEqualTo(null).toDart);

  // Different types.
  final b10 = 10.toBigInt;
  Expect.equals(11.toBigInt, b10.add(1.toBigInt));
  Expect.equals(9.toBigInt, b10.subtract(1.toBigInt));
  Expect.equals(20.toBigInt, b10.multiply(2.toBigInt));
  Expect.equals(1.toBigInt, b10.divide(10.toBigInt));
  Expect.equals(0.toBigInt, b10.modulo(5.toBigInt));
  Expect.equals(100.toBigInt, b10.exponentiate(2.toBigInt));
  // Note that `unsignedRightShift` can not be used with BigInts and always
  // returns a number.
  Expect.equals(1, toInt(t.unsignedRightShift(f)));
  final b1 = 1.toBigInt;
  Expect.isTrue(b1.equals(t).toDart);
  Expect.isFalse(b1.notEquals(t).toDart);
  Expect.isFalse(b1.strictEquals(t).toDart);
  Expect.isTrue(b1.strictNotEquals(t).toDart);
  Expect.equals(b1, b10.and(b1));
  Expect.equals(b10, b10.or(b1));
  Expect.isFalse(b10.not.toDart);
  Expect.isTrue(b10.isTruthy.toDart);
  Expect.isFalse(b10.lessThan(b10).toDart);
  Expect.isTrue(b10.lessThanOrEqualTo(b10).toDart);
  Expect.isFalse(b10.greaterThan(b10).toDart);
  Expect.isTrue(b10.greaterThanOrEqualTo(b10).toDart);
}

void main() {
  extensionTypeTest();
  staticInteropTest();
  dartJsInteropOperatorsTest();
}
