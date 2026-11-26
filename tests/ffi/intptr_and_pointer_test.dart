// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

// 2 arguments: SumPlus42
typedef NativeBinaryOp = Int32 Function(Int32, Int32);
typedef BinaryOp = int Function(int, int);
final sumPlus42 = ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>(
  "SumPlus42",
);

// 4 arguments: Sum4Ints
typedef NativeQuadOp = IntPtr Function(IntPtr, IntPtr, IntPtr, IntPtr);
typedef QuadOp = int Function(int, int, int, int);
final sum4Ints = ffiTestFunctions.lookupFunction<NativeQuadOp, QuadOp>(
  "Sum4Ints",
);

// 10 arguments: SumManyInts
typedef NativeDecenaryOp =
    IntPtr Function(
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
    );
typedef DecenaryOp =
    int Function(int, int, int, int, int, int, int, int, int, int);
final sumManyInts = ffiTestFunctions
    .lookupFunction<NativeDecenaryOp, DecenaryOp>("SumManyInts");

// 11 arguments: SumManyIntsOdd
typedef NativeUndenaryOp =
    IntPtr Function(
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
    );
typedef UndenaryOp =
    int Function(int, int, int, int, int, int, int, int, int, int, int);
final sumManyIntsOdd = ffiTestFunctions
    .lookupFunction<NativeUndenaryOp, UndenaryOp>("SumManyIntsOdd");

// 12 arguments: SumManyInts12
typedef NativeDuodenaryOp =
    IntPtr Function(
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
    );
typedef DuodenaryOp =
    int Function(int, int, int, int, int, int, int, int, int, int, int, int);
final sumManyInts12 = ffiTestFunctions
    .lookupFunction<NativeDuodenaryOp, DuodenaryOp>("SumManyInts12");

// Pointer parameter & return value: Assign1337Index1
typedef Int64PointerUnOp = Pointer<Int64> Function(Pointer<Int64>);
final assign1337Index1 = ffiTestFunctions
    .lookupFunction<Int64PointerUnOp, Int64PointerUnOp>("Assign1337Index1");

void testBinaryInts() {
  Expect.equals(49, sumPlus42(3, 4));
  Expect.equals(42, sumPlus42(0, 0));
  Expect.equals(32, sumPlus42(-10, 0));
}

void testQuadInts() {
  Expect.equals(10, sum4Ints(1, 2, 3, 4));
  Expect.equals(0, sum4Ints(0, 0, 0, 0));
  Expect.equals(-10, sum4Ints(-1, -2, -3, -4));
}

void testTenInts() {
  Expect.equals(55, sumManyInts(1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
  Expect.equals(-55, sumManyInts(-1, -2, -3, -4, -5, -6, -7, -8, -9, -10));
}

void testElevenInts() {
  Expect.equals(66, sumManyIntsOdd(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11));
  Expect.equals(
    -66,
    sumManyIntsOdd(-1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11),
  );
}

void testTwelveInts() {
  Expect.equals(78, sumManyInts12(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12));
  Expect.equals(
    -78,
    sumManyInts12(-1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12),
  );
}

void testPointers() {
  final Pointer<Int64> p = calloc<Int64>(2);
  p[0] = 42;
  p[1] = 1000;
  final Pointer<Int64> result = assign1337Index1(p);
  Expect.equals(1337, result.value);
  Expect.equals(1337, p[1]);
  Expect.equals((p + 1).address, result.address);
  calloc.free(p);
}

void testNullPointer() {
  final Pointer<Int64> nullPtr = Pointer.fromAddress(0);
  Expect.equals(0, nullPtr.address);
}

// 12 smaller integer arguments: SumSmallInts12
typedef NativeSmallInts12Op =
    IntPtr Function(
      Int8,
      Uint8,
      Int16,
      Uint16,
      Int32,
      Uint32,
      Bool,
      Int8,
      Uint8,
      Int16,
      Uint16,
      Int32,
    );
typedef SmallInts12Op =
    int Function(int, int, int, int, int, int, bool, int, int, int, int, int);
final sumSmallInts12 = ffiTestFunctions
    .lookupFunction<NativeSmallInts12Op, SmallInts12Op>("SumSmallInts12");

final returnInt8 = ffiTestFunctions
    .lookupFunction<Int8 Function(IntPtr), int Function(int)>("ReturnInt8");
final returnUint8 = ffiTestFunctions
    .lookupFunction<Uint8 Function(IntPtr), int Function(int)>("ReturnUint8");
final returnInt16 = ffiTestFunctions
    .lookupFunction<Int16 Function(IntPtr), int Function(int)>("ReturnInt16");
final returnUint16 = ffiTestFunctions
    .lookupFunction<Uint16 Function(IntPtr), int Function(int)>("ReturnUint16");
final returnInt32 = ffiTestFunctions
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>("ReturnInt32");
final returnUint32 = ffiTestFunctions
    .lookupFunction<Uint32 Function(IntPtr), int Function(int)>("ReturnUint32");
final returnBool = ffiTestFunctions
    .lookupFunction<Bool Function(IntPtr), bool Function(int)>("ReturnBool");

void testSmallInts() {
  // Test negative signed values and high-bit unsigned values across registers and stack.
  final int res = sumSmallInts12(
    -5, // int8 (register)
    250, // uint8 (register)
    -500, // int16 (register)
    60000, // uint16 (register)
    -100000, // int32 (register)
    100000, // uint32 (register)
    true, // bool (register/stack)
    -10, // int8 (register/stack)
    200, // uint8 (stack)
    -1000, // int16 (stack)
    50000, // uint16 (stack)
    -200000, // int32 (stack)
  );
  final int expected =
      -5 +
      250 +
      -500 +
      60000 +
      -100000 +
      100000 +
      1 +
      -10 +
      200 +
      -1000 +
      50000 +
      -200000;
  Expect.equals(expected, res);
}

void testSmallIntReturns() {
  Expect.equals(-5, returnInt8(0x123456FB));
  Expect.equals(127, returnInt8(0x1234567F));
  Expect.equals(250, returnUint8(0x123456FA));
  Expect.equals(-500, returnInt16(0x1234FE0C));
  Expect.equals(60000, returnUint16(0x1234EA60));
  Expect.equals(-1, returnInt32(-1));
  Expect.equals(-100000, returnInt32(-100000));
  Expect.equals(0xF0000000, returnUint32(0xF0000000));
  Expect.equals(false, returnBool(0));
  Expect.equals(true, returnBool(1));
}

void main() {
  for (int i = 0; i < 10; ++i) {
    testBinaryInts();
    testQuadInts();
    testTenInts();
    testElevenInts();
    testTwelveInts();
    testSmallInts();
    testSmallIntReturns();
    testPointers();
    testNullPointer();
  }
}
