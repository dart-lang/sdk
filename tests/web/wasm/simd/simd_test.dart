// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'package:expect/expect.dart';
import 'dart:_wasm';

void main() {
  final failures = <(String, Object, StackTrace)>[];

  void runTest(String name, void Function() testFn) {
    print('Running $name...');
    try {
      testFn();
    } catch (e, st) {
      print('  Failed: $e');
      failures.add((name, e, st));
    }
  }

  runTest('testI64x2', _testI64x2);
  runTest('testI8x16', _testI8x16);
  runTest('testI32x4', _testI32x4);
  runTest('testI16x8', _testI16x8);
  runTest('testF32x4', _testF32x4);
  runTest('testF64x2', _testF64x2);
  runTest('testV128', _testV128);

  if (failures.isNotEmpty) {
    print('\n${failures.length} tests failed:');
    for (var (name, e, st) in failures) {
      print('  $name: $e');
      print(st);
      print('');
    }
    throw 'Tests failed';
  } else {
    print('\nAll tests passed!');
  }
}

void _testI8x16() {
  // splat
  var v1 = WasmI8x16.splat(WasmI32.fromInt(10));
  var v2 = WasmI8x16.splat(WasmI32.fromInt(20));

  Expect.equals(v1.extractLaneSigned(0).toIntSigned(), 10);
  Expect.equals(v1.extractLaneUnsigned(0).toIntUnsigned(), 10);
  Expect.equals(v1.extractLaneSigned(15).toIntSigned(), 10);
  Expect.equals(v1.extractLaneUnsigned(15).toIntUnsigned(), 10);

  // replaceLane
  var v3 = v1.replaceLane(0, WasmI32.fromInt(5));
  Expect.equals(v3.extractLaneSigned(0).toIntSigned(), 5);
  Expect.equals(v3.extractLaneSigned(1).toIntSigned(), 10);

  // +
  var vAdd = v1 + v2;
  Expect.equals(vAdd.extractLaneSigned(0).toIntSigned(), 30);
  Expect.equals(vAdd.extractLaneSigned(15).toIntSigned(), 30);

  // -
  var vSub = v2 - v1;
  Expect.equals(vSub.extractLaneSigned(0).toIntSigned(), 10);
  Expect.equals(vSub.extractLaneSigned(15).toIntSigned(), 10);

  // unary -
  var vNeg = -v1;
  Expect.equals(vNeg.extractLaneSigned(0).toIntSigned(), -10);
  Expect.equals(vNeg.extractLaneSigned(15).toIntSigned(), -10);

  // eq
  var vEq = v1.eq(WasmI8x16.splat(WasmI32.fromInt(10))); // 10 == 10
  _expectCmpTrue(vEq.extractLaneSigned(0).toIntSigned()); // True is -1 (all 1s)
  vEq = v1.eq(WasmI8x16.splat(WasmI32.fromInt(11))); // 10 != 11
  _expectCmpFalse(vEq.extractLaneSigned(0).toIntSigned()); // False is 0
}

void _testI16x8() {
  // splat
  var v1 = WasmI16x8.splat(WasmI32.fromInt(10));
  var v2 = WasmI16x8.splat(WasmI32.fromInt(20));

  Expect.equals(v1.extractLaneSigned(0).toIntSigned(), 10);
  Expect.equals(v1.extractLaneUnsigned(0).toIntUnsigned(), 10);
  Expect.equals(v1.extractLaneSigned(7).toIntSigned(), 10);
  Expect.equals(v1.extractLaneUnsigned(7).toIntUnsigned(), 10);

  // replaceLane
  var v3 = v1.replaceLane(0, WasmI32.fromInt(5));
  Expect.equals(v3.extractLaneSigned(0).toIntSigned(), 5);
  Expect.equals(v3.extractLaneSigned(1).toIntSigned(), 10);

  // +
  var vAdd = v1 + v2;
  Expect.equals(vAdd.extractLaneSigned(0).toIntSigned(), 30);
  Expect.equals(vAdd.extractLaneSigned(7).toIntSigned(), 30);

  // -
  var vSub = v2 - v1;
  Expect.equals(vSub.extractLaneSigned(0).toIntSigned(), 10);
  Expect.equals(vSub.extractLaneSigned(7).toIntSigned(), 10);

  // *
  var vMul = v1 * v2;
  Expect.equals(vMul.extractLaneSigned(0).toIntSigned(), 200);
  Expect.equals(vMul.extractLaneSigned(7).toIntSigned(), 200);

  // unary -
  var vNeg = -v1;
  Expect.equals(vNeg.extractLaneSigned(0).toIntSigned(), -10);
  Expect.equals(vNeg.extractLaneSigned(7).toIntSigned(), -10);

  // dotProduct
  var vDot = v1.dotProduct(v2);
  Expect.equals(vDot.extractLane(0).toIntSigned(), 400); // 10*20 + 10*20
  Expect.equals(vDot.extractLane(3).toIntSigned(), 400);

  // eq
  var vEq = v1.eq(WasmI16x8.splat(WasmI32.fromInt(10)));
  _expectCmpTrue(vEq.extractLaneSigned(0).toIntSigned());
  vEq = v1.eq(WasmI16x8.splat(WasmI32.fromInt(11)));
  _expectCmpFalse(vEq.extractLaneSigned(0).toIntSigned());
}

void _testI32x4() {
  // splat
  var v1 = WasmI32x4.splat(WasmI32.fromInt(10));
  var v2 = WasmI32x4.splat(WasmI32.fromInt(20));

  Expect.equals(v1.extractLane(0).toIntSigned(), 10);
  Expect.equals(v1.extractLane(1).toIntSigned(), 10);
  Expect.equals(v1.extractLane(2).toIntSigned(), 10);
  Expect.equals(v1.extractLane(3).toIntSigned(), 10);

  // replaceLane
  var v3 = v1.replaceLane(0, WasmI32.fromInt(5));
  Expect.equals(v3.extractLane(0).toIntSigned(), 5);
  Expect.equals(v3.extractLane(1).toIntSigned(), 10);

  // +
  var vAdd = v1 + v2;
  Expect.equals(vAdd.extractLane(0).toIntSigned(), 30);
  Expect.equals(vAdd.extractLane(3).toIntSigned(), 30);

  // -
  var vSub = v2 - v1;
  Expect.equals(vSub.extractLane(0).toIntSigned(), 10);
  Expect.equals(vSub.extractLane(3).toIntSigned(), 10);

  // *
  var vMul = v1 * v2;
  Expect.equals(vMul.extractLane(0).toIntSigned(), 200);
  Expect.equals(vMul.extractLane(3).toIntSigned(), 200);

  // unary -
  var vNeg = -v1;
  Expect.equals(vNeg.extractLane(0).toIntSigned(), -10);
  Expect.equals(vNeg.extractLane(3).toIntSigned(), -10);

  // eq
  var vEq = v1.eq(WasmI32x4.splat(WasmI32.fromInt(10)));
  _expectCmpTrue(vEq.extractLane(0).toIntSigned());
  var s11 = WasmI32x4.splat(WasmI32.fromInt(11));
  vEq = v1.eq(s11);
  _expectCmpFalse(vEq.extractLane(0).toIntSigned());
}

void _testI64x2() {
  // splat
  var v1 = WasmI64x2.splat(WasmI64.fromInt(10));
  var v2 = WasmI64x2.splat(WasmI64.fromInt(20));

  Expect.equals(v1.extractLane(0).toInt(), 10);
  Expect.equals(v1.extractLane(1).toInt(), 10);

  // replaceLane
  var v3 = v1.replaceLane(0, WasmI64.fromInt(5));
  Expect.equals(v3.extractLane(0).toInt(), 5);
  Expect.equals(v3.extractLane(1).toInt(), 10);

  // +
  var vAdd = v1 + v2;
  Expect.equals(vAdd.extractLane(0).toInt(), 30);
  Expect.equals(vAdd.extractLane(1).toInt(), 30);

  // -
  var vSub = v2 - v1;
  Expect.equals(vSub.extractLane(0).toInt(), 10);
  Expect.equals(vSub.extractLane(1).toInt(), 10);

  // *
  var vMul = v1 * v2;
  Expect.equals(vMul.extractLane(0).toInt(), 200);
  Expect.equals(vMul.extractLane(1).toInt(), 200);

  // unary -
  var vNeg = -v1;
  Expect.equals(vNeg.extractLane(0).toInt(), -10);
  Expect.equals(vNeg.extractLane(1).toInt(), -10);

  // eq
  var vEq = v1.eq(WasmI64x2.splat(WasmI64.fromInt(10)));
  _expectCmpTrue(vEq.extractLane(0).toInt());
  vEq = v1.eq(WasmI64x2.splat(WasmI64.fromInt(11)));
  _expectCmpFalse(vEq.extractLane(0).toInt());
}

void _testF32x4() {
  // splat
  var v1 = WasmF32x4.splat(WasmF32.fromDouble(10.5));

  Expect.equals(v1.extractLane(0).toDouble(), 10.5);
  Expect.equals(v1.extractLane(3).toDouble(), 10.5);

  // replaceLane
  var v2 = v1.replaceLane(0, WasmF32.fromDouble(5.5));
  Expect.equals(v2.extractLane(0).toDouble(), 5.5);
  Expect.equals(v2.extractLane(1).toDouble(), 10.5);

  // eq
  var vEq = v1.eq(WasmF32x4.splat(WasmF32.fromDouble(10.5)));
  _expectCmpTrue(vEq.extractLane(0).toIntSigned());
  vEq = v1.eq(WasmF32x4.splat(WasmF32.fromDouble(11.5)));
  _expectCmpFalse(vEq.extractLane(0).toIntSigned());
}

void _testF64x2() {
  // splat
  var v1 = WasmF64x2.splat(WasmF64.fromDouble(10.5));

  Expect.equals(v1.extractLane(0).toDouble(), 10.5);
  Expect.equals(v1.extractLane(1).toDouble(), 10.5);

  // replaceLane
  var v2 = v1.replaceLane(0, WasmF64.fromDouble(5.5));
  Expect.equals(v2.extractLane(0).toDouble(), 5.5);
  Expect.equals(v2.extractLane(1).toDouble(), 10.5);

  // eq
  var vEq = v1.eq(WasmF64x2.splat(WasmF64.fromDouble(10.5)));
  _expectCmpTrue(vEq.extractLane(0).toInt());
  vEq = v1.eq(WasmF64x2.splat(WasmF64.fromDouble(11.5)));
  _expectCmpFalse(vEq.extractLane(0).toInt());
}

void _testV128() {
  // Use WasmI32x4 as a concrete WasmV128
  var v1 = WasmI32x4.splat(WasmI32.fromInt(0xAAAAAAAA));
  var v2 = WasmI32x4.splat(WasmI32.fromInt(0x55555555));
  // & with heterogeneous lanes
  var v3 = WasmI32x4.splat(WasmI32.fromInt(0x12345678))
      .replaceLane(1, WasmI32.fromInt(0x9ABCDEF0))
      .replaceLane(2, WasmI32.fromInt(0x0FEDCBA9))
      .replaceLane(3, WasmI32.fromInt(0x87654321));
  var v4 = WasmI32x4.splat(WasmI32.fromInt(0x87654321))
      .replaceLane(1, WasmI32.fromInt(0x0FEDCBA9))
      .replaceLane(2, WasmI32.fromInt(0x9ABCDEF0))
      .replaceLane(3, WasmI32.fromInt(0x12345678));

  // ~
  var vNot = WasmI32x4(~v1);
  Expect.equals(vNot.extractLane(0).toIntUnsigned(), 0x55555555);

  // &
  var vAnd = WasmI32x4(v1 & v2);
  _expectCmpFalse(vAnd.extractLane(0).toIntSigned());

  var vAnd2 = WasmI32x4(v3 & v4);
  Expect.equals(vAnd2.extractLane(0).toIntUnsigned(), 0x12345678 & 0x87654321);
  Expect.equals(vAnd2.extractLane(1).toIntUnsigned(), 0x9ABCDEF0 & 0x0FEDCBA9);
  Expect.equals(vAnd2.extractLane(2).toIntUnsigned(), 0x0FEDCBA9 & 0x9ABCDEF0);
  Expect.equals(vAnd2.extractLane(3).toIntUnsigned(), 0x87654321 & 0x12345678);

  // |
  var vOr = WasmI32x4(v1 | v2);
  _expectCmpTrue(vOr.extractLane(0).toIntSigned());

  // | with heterogeneous lanes
  var vOr2 = WasmI32x4(v3 | v4);
  Expect.equals(vOr2.extractLane(0).toIntUnsigned(), 0x12345678 | 0x87654321);
  Expect.equals(vOr2.extractLane(1).toIntUnsigned(), 0x9ABCDEF0 | 0x0FEDCBA9);
  Expect.equals(vOr2.extractLane(2).toIntUnsigned(), 0x0FEDCBA9 | 0x9ABCDEF0);
  Expect.equals(vOr2.extractLane(3).toIntUnsigned(), 0x87654321 | 0x12345678);

  // xor
  var vXor = WasmI32x4(v1 ^ v1);
  _expectCmpFalse(vXor.extractLane(0).toIntSigned());

  // ^ with heterogeneous lanes
  var vXor2 = WasmI32x4(v3 ^ v4);
  Expect.equals(vXor2.extractLane(0).toIntUnsigned(), 0x12345678 ^ 0x87654321);
  Expect.equals(vXor2.extractLane(1).toIntUnsigned(), 0x9ABCDEF0 ^ 0x0FEDCBA9);
  Expect.equals(vXor2.extractLane(2).toIntUnsigned(), 0x0FEDCBA9 ^ 0x9ABCDEF0);
  Expect.equals(vXor2.extractLane(3).toIntUnsigned(), 0x87654321 ^ 0x12345678);

  // andNot
  var vAndNot = WasmI32x4(v1.andNot(v1));
  _expectCmpFalse(vAndNot.extractLane(0).toIntSigned());

  // andNot with heterogeneous lanes
  var vAndNot2 = WasmI32x4(v3.andNot(v4));
  Expect.equals(
    vAndNot2.extractLane(0).toIntUnsigned(),
    0x12345678 & ~0x87654321,
  );
  Expect.equals(
    vAndNot2.extractLane(1).toIntUnsigned(),
    0x9ABCDEF0 & ~0x0FEDCBA9,
  );
  Expect.equals(
    vAndNot2.extractLane(2).toIntUnsigned(),
    0x0FEDCBA9 & ~0x9ABCDEF0,
  );
  Expect.equals(
    vAndNot2.extractLane(3).toIntUnsigned(),
    0x87654321 & ~0x12345678,
  );

  // bitSelect
  var mask = WasmI32x4.splat(WasmI32.fromInt(0xFFFFFFFF));
  var vSel = WasmI32x4(mask.bitSelect(v1, v2));
  Expect.equals(vSel.extractLane(0).toIntUnsigned(), 0xAAAAAAAA);

  mask = WasmI32x4.splat(WasmI32.fromInt(0));
  vSel = WasmI32x4(mask.bitSelect(v1, v2));
  Expect.equals(vSel.extractLane(0).toIntUnsigned(), 0x55555555);

  // bitSelect with heterogeneous mask and lanes
  var mask2 = WasmI32x4.splat(WasmI32.fromInt(0xF0F0F0F0))
      .replaceLane(1, WasmI32.fromInt(0x0F0F0F0F))
      .replaceLane(2, WasmI32.fromInt(0x0AAAAAAA))
      .replaceLane(3, WasmI32.fromInt(0x05555555));
  var vSel2 = WasmI32x4(mask2.bitSelect(v3, v4));

  int bitSelect(int m, int a, int b) => (a & m) | (b & ~m);

  Expect.equals(
    vSel2.extractLane(0).toIntUnsigned(),
    bitSelect(0xF0F0F0F0, 0x12345678, 0x87654321),
  );
  Expect.equals(
    vSel2.extractLane(1).toIntUnsigned(),
    bitSelect(0x0F0F0F0F, 0x9ABCDEF0, 0x0FEDCBA9),
  );
  Expect.equals(
    vSel2.extractLane(2).toIntUnsigned(),
    bitSelect(0x0AAAAAAA, 0x0FEDCBA9, 0x9ABCDEF0),
  );
  Expect.equals(
    vSel2.extractLane(3).toIntUnsigned(),
    bitSelect(0x05555555, 0x87654321, 0x12345678),
  );
}

void _expectCmpTrue(int v) => Expect.equals(v, -1);
void _expectCmpFalse(int v) => Expect.equals(v, 0);
