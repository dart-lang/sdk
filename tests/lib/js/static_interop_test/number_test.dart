// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that external members returning numbers have correct semantics.

import 'dart:js_interop';

import 'package:expect/expect.dart';

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

  Expect.equals(0, integerAsInt);
  Expect.equals(0, integerAsIntE);
  Expect.equals(0.0, integerAsDouble);
  Expect.equals(0, integerAsNum);
  Expect.equals(0.0, integerAsJSNumber.toDartDouble);
  Expect.equals(0, integerAsJSNumber.toDartInt);

  Expect.equals(0, integerAsNullInt);
  Expect.equals(0, integerAsNullableIntE);
  Expect.equals(0.0, integerAsNullDouble);
  Expect.equals(0, integerAsNullNum);
  Expect.equals(0.0, integerAsNullJSNumber!.toDartDouble);
  Expect.equals(0, integerAsNullJSNumber!.toDartInt);

  Expect.throws(() => floatAsInt);
  Expect.throws(() => floatAsIntE);
  Expect.equals(0.5, floatAsDouble);
  Expect.equals(0.5, floatAsNum);
  Expect.equals(0.5, floatAsJSNumber.toDartDouble);
  Expect.throws(() => floatAsJSNumber.toDartInt);

  Expect.throws(() => floatAsNullInt);
  Expect.throws(() => floatAsNullableIntE);
  Expect.equals(0.5, floatAsNullDouble);
  Expect.equals(0.5, floatAsNullNum);
  Expect.equals(0.5, floatAsNullJSNumber!.toDartDouble);
  Expect.throws(() => floatAsNullJSNumber!.toDartInt);

  Expect.throws(() => nullAsInt);
  Expect.throws(() => nullAsIntE);
  Expect.throws(() => nullAsDouble);
  Expect.throws(() => nullAsNum);
  Expect.throws(() => nullAsJSNumber);

  Expect.isNull(nullAsNullInt);
  Expect.isNull(nullAsNullableIntE);
  Expect.isNull(nullAsNullDouble);
  Expect.isNull(nullAsNullNum);
  Expect.isNull(nullAsNullJSNumber);
}
