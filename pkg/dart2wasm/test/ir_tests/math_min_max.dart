// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=test|sink
// globalFilter=DoesNotMatch
// tableFilter=DoesNotMatch
// compilerOption=-O2

import 'dart:math' as math;

final ktrue = int.parse('1') == 1;

final intA = ktrue ? 1 : 2;
final intB = ktrue ? 2 : 1;
final doubleA = ktrue ? 1.5 : 2.5;
final doubleB = ktrue ? 2.5 : 1.5;
final numIntA = ktrue ? intA : 1.2;
final numIntB = ktrue ? intB : 1.2;

@pragma('wasm:never-inline')
void main() {
  testMinIntInt();
  testMaxIntInt();
  testMinDoubleDouble();
  testMaxDoubleDouble();
  testMinIntDouble();
  testMaxIntDouble();
  testMinNumNum();
  testMaxNumNum();
}

@pragma('wasm:never-inline')
void testMinIntInt() => sinkInt(math.min(intA, intB));

@pragma('wasm:never-inline')
void testMaxIntInt() => sinkInt(math.max(intA, intB));

@pragma('wasm:never-inline')
void testMinDoubleDouble() => sinkDouble(math.min(doubleA, doubleB));

@pragma('wasm:never-inline')
void testMaxDoubleDouble() => sinkDouble(math.max(doubleA, doubleB));

@pragma('wasm:never-inline')
void testMinIntDouble() => sinkNum(math.min(intA, doubleA));

@pragma('wasm:never-inline')
void testMaxIntDouble() => sinkNum(math.max(intA, doubleA));

@pragma('wasm:never-inline')
void testMinNumNum() => sinkNum(math.min(numIntA, numIntB));

@pragma('wasm:never-inline')
void testMaxNumNum() => sinkNum(math.max(numIntA, numIntB));

@pragma('wasm:never-inline')
void sinkInt(int x) => print(x);

@pragma('wasm:never-inline')
void sinkDouble(double x) => print(x);

@pragma('wasm:never-inline')
void sinkNum(num x) => print(x);
