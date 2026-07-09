// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=test|roundTrip
// globalFilter=DoesNotMatch
// tableFilter=DoesNotMatch

import 'dart:js_interop';

@JS()
external double roundTripDouble(double d);

@JS()
external double? roundTripDoubleNullable(double? d);

final ktrue = int.parse('1') == 1;

final doubleValue = ktrue ? 1.1 : 2.1;
final doubleValueNullable = ktrue ? doubleValue : null;

@pragma('wasm:never-inline')
void main() {
  testDoubleConstant();
  testDoubleConstantNullable();
  testDoubleValue();
  testDoubleValueNullable();
}

@pragma('wasm:never-inline')
void testDoubleConstant() {
  sinkDouble(roundTripDouble(1.1));
}

@pragma('wasm:never-inline')
void testDoubleConstantNullable() {
  sinkDoubleNullable(roundTripDoubleNullable(null));
}

@pragma('wasm:never-inline')
void testDoubleValue() {
  sinkDouble(roundTripDouble(doubleValue));
}

@pragma('wasm:never-inline')
void testDoubleValueNullable() {
  sinkDoubleNullable(roundTripDoubleNullable(doubleValueNullable));
}

@pragma('wasm:never-inline')
void sinkDouble(double b) => print(b);

@pragma('wasm:never-inline')
void sinkDoubleNullable(double? b) => print(b);
