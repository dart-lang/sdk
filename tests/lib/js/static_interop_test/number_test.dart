// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class
// Requirements=nnbd-strong

// Test that external members returning numbers have correct semantics.

@JS()
library number_test;

import 'dart:js_interop';

import 'package:expect/expect.dart';
import 'package:expect/minitest.dart';

extension type IntE(int _) {}

extension type NullableIntE(int? _) {}

@JS()
external void eval(String code);

// Integer value.

@JS('integer')
external int get integerAsInt;

@JS('integer')
external IntE get integerAsIntE;

@JS('integer')
external double get integerAsDouble;

@JS('integer')
external num get integerAsNum;

@JS('integer')
external JSNumber get integerAsJSNumber;

// Integer value with nullable type.

@JS('integer')
external int? get integerAsNullInt;

@JS('integer')
external NullableIntE get integerAsNullableIntE;

@JS('integer')
external double? get integerAsNullDouble;

@JS('integer')
external num? get integerAsNullNum;

@JS('integer')
external JSNumber? get integerAsNullJSNumber;

// Float value.

@JS('float')
external int get floatAsInt;

@JS('float')
external IntE get floatAsIntE;

@JS('float')
external double get floatAsDouble;

@JS('float')
external num get floatAsNum;

@JS('float')
external JSNumber get floatAsJSNumber;

// Float value with nullable type.

@JS('float')
external int? get floatAsNullInt;

@JS('float')
external NullableIntE get floatAsNullableIntE;

@JS('float')
external double? get floatAsNullDouble;

@JS('float')
external num? get floatAsNullNum;

@JS('float')
external JSNumber? get floatAsNullJSNumber;

// Null value with non-nullable type.

@JS('nullVal')
external int get nullAsInt;

@JS('nullVal')
external IntE get nullAsIntE;

@JS('nullVal')
external double get nullAsDouble;

@JS('nullVal')
external num get nullAsNum;

@JS('nullVal')
external JSNumber get nullAsJSNumber;

// Null value with nullable type.

@JS('nullVal')
external int? get nullAsNullInt;

@JS('nullVal')
external NullableIntE get nullAsNullableIntE;

@JS('nullVal')
external double? get nullAsNullDouble;

@JS('nullVal')
external num? get nullAsNullNum;

@JS('nullVal')
external JSNumber? get nullAsNullJSNumber;

void main() {
  eval('''
    globalThis.integer = 0;
    globalThis.float = 0.5;
    globalThis.nullVal = null;
  ''');

  expect(integerAsInt, 0);
  expect(integerAsIntE, 0);
  expect(integerAsDouble, 0.0);
  expect(integerAsNum, 0);
  expect(integerAsJSNumber.toDartDouble, 0.0);
  expect(integerAsJSNumber.toDartInt, 0);

  expect(integerAsNullInt, 0);
  expect(integerAsNullableIntE, 0);
  expect(integerAsNullDouble, 0.0);
  expect(integerAsNullNum, 0);
  expect(integerAsNullJSNumber!.toDartDouble, 0.0);
  expect(integerAsNullJSNumber!.toDartInt, 0);

  Expect.throws(() => floatAsInt);
  Expect.throws(() => floatAsIntE);
  expect(floatAsDouble, 0.5);
  expect(floatAsNum, 0.5);
  expect(floatAsJSNumber.toDartDouble, 0.5);
  Expect.throws(() => floatAsJSNumber.toDartInt);

  Expect.throws(() => floatAsNullInt);
  Expect.throws(() => floatAsNullableIntE);
  expect(floatAsNullDouble, 0.5);
  expect(floatAsNullNum, 0.5);
  expect(floatAsNullJSNumber!.toDartDouble, 0.5);
  Expect.throws(() => floatAsNullJSNumber!.toDartInt);

  Expect.throws(() => nullAsInt);
  Expect.throws(() => nullAsIntE);
  Expect.throws(() => nullAsDouble);
  Expect.throws(() => nullAsNum);
  Expect.throws(() => nullAsJSNumber);

  expect(nullAsNullInt, null);
  expect(nullAsNullableIntE, null);
  expect(nullAsNullDouble, null);
  expect(nullAsNullNum, null);
  expect(nullAsNullJSNumber, null);
}
