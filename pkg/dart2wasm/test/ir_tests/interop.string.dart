// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=test|roundTrip

import 'dart:js_interop';

@JS()
external String roundTripString(String s);

@JS()
external String? roundTripStringNullable(String? s);

final ktrue = int.parse('1') == 1;

final stringValue = ktrue ? 'a' : 'b';
final stringValueNullable = ktrue ? stringValue : null;

@pragma('wasm:never-inline')
void main() {
  testStringConstant();
  testStringConstantNullable();
  testStringValue();
  testStringValueNullable();
}

@pragma('wasm:never-inline')
void testStringConstant() {
  sinkString(roundTripString('a'));
}

@pragma('wasm:never-inline')
void testStringConstantNullable() {
  sinkStringNullable(roundTripStringNullable(null));
}

@pragma('wasm:never-inline')
void testStringValue() {
  sinkString(roundTripString(stringValue));
}

@pragma('wasm:never-inline')
void testStringValueNullable() {
  sinkStringNullable(roundTripStringNullable(stringValueNullable));
}

@pragma('wasm:never-inline')
void sinkString(String b) => print(b);

@pragma('wasm:never-inline')
void sinkStringNullable(String? b) => print(b);
