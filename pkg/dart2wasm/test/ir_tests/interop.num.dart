// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=test|roundTrip
// globalFilter=DoesNotMatch
// tableFilter=DoesNotMatch

import 'dart:js_interop';

@JS()
external num roundTripNum(num n);

@JS()
external num? roundTripNumNullable(num? n);

final ktrue = int.parse('1') == 1;

final numValue = ktrue ? 1 : 1.0;
final numValueNullable = ktrue ? numValue : null;

@pragma('wasm:never-inline')
void main() {
  testNumConstant();
  testNumConstantDouble();
  testNumConstantNullable();
  testNumValue();
  testNumValueNullable();
}

@pragma('wasm:never-inline')
void testNumConstant() {
  sinkNum(roundTripNum(1));
}

@pragma('wasm:never-inline')
void testNumConstantDouble() {
  sinkNum(roundTripNum(1.1));
}

@pragma('wasm:never-inline')
void testNumConstantNullable() {
  sinkNumNullable(roundTripNumNullable(null));
}

@pragma('wasm:never-inline')
void testNumValue() {
  sinkNum(roundTripNum(numValue));
}

@pragma('wasm:never-inline')
void testNumValueNullable() {
  sinkNumNullable(roundTripNumNullable(numValueNullable));
}

@pragma('wasm:never-inline')
void sinkNum(num b) => print(b);

@pragma('wasm:never-inline')
void sinkNumNullable(num? b) => print(b);
