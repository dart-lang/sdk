// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=test|roundTrip

import 'dart:js_interop';

@JS()
external int roundTripInt(int i);

@JS()
external int? roundTripIntNullable(int? i);

final ktrue = int.parse('1') == 1;

final intValue = ktrue ? 1 : 2;
final intValueNullable = ktrue ? intValue : null;

@pragma('wasm:never-inline')
void main() {
  testIntConstant();
  testIntConstantNullable();
  testIntValue();
  testIntValueNullable();
}

@pragma('wasm:never-inline')
void testIntConstant() {
  sinkInt(roundTripInt(1));
}

@pragma('wasm:never-inline')
void testIntConstantNullable() {
  sinkIntNullable(roundTripIntNullable(null));
}

@pragma('wasm:never-inline')
void testIntValue() {
  sinkInt(roundTripInt(intValue));
}

@pragma('wasm:never-inline')
void testIntValueNullable() {
  sinkIntNullable(roundTripIntNullable(intValueNullable));
}

@pragma('wasm:never-inline')
void sinkInt(int b) => print(b);

@pragma('wasm:never-inline')
void sinkIntNullable(int? b) => print(b);
