// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=test|roundTrip

import 'dart:js_interop';

@JS()
external bool roundTripBool(bool b);

@JS()
external bool? roundTripBoolNullable(bool? b);

final ktrue = int.parse('1') == 1;

final boolValue = ktrue;
final boolValueNullable = ktrue ? boolValue : null;

@pragma('wasm:never-inline')
void main() {
  testBoolConstant();
  testBoolConstantNullable();
  testBoolValue();
  testBoolValueNullable();
}

@pragma('wasm:never-inline')
void testBoolConstant() {
  sinkBool(roundTripBool(true));
}

@pragma('wasm:never-inline')
void testBoolConstantNullable() {
  sinkBoolNullable(roundTripBoolNullable(null));
}

@pragma('wasm:never-inline')
void testBoolValue() {
  sinkBool(roundTripBool(boolValue));
}

@pragma('wasm:never-inline')
void testBoolValueNullable() {
  sinkBoolNullable(roundTripBoolNullable(boolValueNullable));
}

@pragma('wasm:never-inline')
void sinkBool(bool b) => print(b);

@pragma('wasm:never-inline')
void sinkBoolNullable(bool? b) => print(b);
