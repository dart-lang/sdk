// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--cfg

import 'package:expect/expect.dart';

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int doubleEqual(double a, double b) => a == b ? 1 : 0;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int doubleIsNaN(double a) => a.isNaN ? 1 : 0;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int doubleLess(double a, double b) => a < b ? 1 : 0;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int doubleLessOrEqual(double a, double b) => a <= b ? 1 : 0;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int doubleGreater(double a, double b) => a > b ? 1 : 0;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int doubleGreaterOrEqual(double a, double b) => a >= b ? 1 : 0;

// Comparisons against constants. Includes constant on the left and right to
// cover when it gets swapped on canonicalization.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int doubleSign(double a) => 0.0 < a ? 1 : (a < 0.0 ? -1 : 0);

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int intOps(int a, int b) {
  int r = 0;
  r += a + b;
  r += a - b;
  r += a * b;
  r += a & b;
  r += a | b;
  r += a ^ b;
  r += a << 2;
  r += a >> 1;
  r += a >>> 1;
  r += -a;
  r += ~b;
  return r;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int greaterOrEqual(int a, int b) => a >= b ? 1 : 0;

void main() {
  final int0 = int.parse('0');
  final int3 = int.parse('3');
  final int5 = int.parse('5');
  final int10 = int.parse('10');
  final negFive = int.parse('-5');

  // Int operations
  Expect.equals(108, intOps(int10, int3));

  // Greater or equal
  Expect.equals(1, greaterOrEqual(int5, int3));
  Expect.equals(1, greaterOrEqual(int5, int5));
  Expect.equals(0, greaterOrEqual(int3, int5));
  Expect.equals(1, greaterOrEqual(int0, negFive));
  Expect.equals(0, greaterOrEqual(negFive, int0));

  final d1 = double.parse('1.5');
  final d2 = double.parse('2.5');
  final zero = double.parse('0.0');
  final negZero = double.parse('-0.0');
  final nan = double.parse('NaN');

  // Double equality (IEEE: NaN != NaN, 0.0 == -0.0)
  Expect.equals(1, doubleEqual(d1, d1));
  Expect.equals(0, doubleEqual(d1, d2));
  Expect.equals(1, doubleEqual(zero, negZero));
  Expect.equals(0, doubleEqual(nan, nan));

  // isNaN is lowered to doubleNotEqual(x, x)
  Expect.equals(0, doubleIsNaN(d1));
  Expect.equals(1, doubleIsNaN(nan));

  // Double ordering (all false when either operand is NaN)
  Expect.equals(1, doubleLess(d1, d2));
  Expect.equals(0, doubleLess(d2, d1));
  Expect.equals(0, doubleLess(d1, d1));
  Expect.equals(0, doubleLess(nan, d1));

  Expect.equals(1, doubleLessOrEqual(d1, d2));
  Expect.equals(1, doubleLessOrEqual(d1, d1));
  Expect.equals(0, doubleLessOrEqual(d2, d1));
  Expect.equals(0, doubleLessOrEqual(d1, nan));

  Expect.equals(1, doubleGreater(d2, d1));
  Expect.equals(0, doubleGreater(d1, d2));
  Expect.equals(0, doubleGreater(d1, d1));
  Expect.equals(0, doubleGreater(nan, d1));

  Expect.equals(1, doubleGreaterOrEqual(d2, d1));
  Expect.equals(1, doubleGreaterOrEqual(d1, d1));
  Expect.equals(0, doubleGreaterOrEqual(d1, d2));
  Expect.equals(0, doubleGreaterOrEqual(d1, nan));

  Expect.equals(1, doubleSign(d1));
  Expect.equals(-1, doubleSign(double.parse('-1.5')));
  Expect.equals(0, doubleSign(zero));
  Expect.equals(0, doubleSign(negZero));
  Expect.equals(0, doubleSign(nan));
}
