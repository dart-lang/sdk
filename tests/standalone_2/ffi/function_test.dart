// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers.

library FfiTest;

import 'dart:ffi' as ffi;

import 'dylib_utils.dart';

import "package:expect/expect.dart";

void main() {
  testNativeFunctionFromCast();
  testNativeFunctionFromLookup();
  test64bitInterpretations();
  testTruncation();
  testNativeFunctionDoubles();
  testNativeFunctionFloats();
  testNativeFunctionManyArguments1();
  testNativeFunctionManyArguments2();
  testNativeFunctionManyArguments3();
  testNativeFunctionPointer();
  testNullInt();
  testNullDouble();
  testNullManyArgs();
  testNullPointers();
  testFloatRounding();
  testVoidReturn();
  testNoArgs();
}

ffi.DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

typedef NativeBinaryOp = ffi.Int32 Function(ffi.Int32, ffi.Int32);
typedef UnaryOp = int Function(int);
typedef BinaryOp = int Function(int, int);
typedef GenericBinaryOp<T> = int Function(int, T);

void testNativeFunctionFromCast() {
  ffi.Pointer<ffi.IntPtr> p1 = ffi.allocate();
  ffi.Pointer<ffi.NativeFunction<NativeBinaryOp>> p2 = p1.cast();
  BinaryOp f = p2.asFunction<BinaryOp>();
  BinaryOp f2 = p2.asFunction<GenericBinaryOp<int>>();
  p1.free();
}

typedef NativeQuadOpSigned = ffi.Int64 Function(
    ffi.Int64, ffi.Int32, ffi.Int16, ffi.Int8);
typedef QuadOp = int Function(int, int, int, int);
typedef NativeQuadOpUnsigned = ffi.Uint64 Function(
    ffi.Uint64, ffi.Uint32, ffi.Uint16, ffi.Uint8);

void testNativeFunctionFromLookup() {
  BinaryOp sumPlus42 =
      ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");
  Expect.equals(49, sumPlus42(3, 4));

  QuadOp intComputation = ffiTestFunctions
      .lookupFunction<NativeQuadOpSigned, QuadOp>("IntComputation");
  Expect.equals(625, intComputation(125, 250, 500, 1000));

  Expect.equals(
      0x7FFFFFFFFFFFFFFF, intComputation(0, 0, 0, 0x7FFFFFFFFFFFFFFF));
  Expect.equals(
      -0x8000000000000000, intComputation(0, 0, 0, -0x8000000000000000));
}

void test64bitInterpretations() {
  QuadOp uintComputation = ffiTestFunctions
      .lookupFunction<NativeQuadOpUnsigned, QuadOp>("UintComputation");

  // 2 ^ 63 - 1
  Expect.equals(
      0x7FFFFFFFFFFFFFFF, uintComputation(0, 0, 0, 0x7FFFFFFFFFFFFFFF));
  // -2 ^ 63 interpreted as 2 ^ 63
  Expect.equals(
      -0x8000000000000000, uintComputation(0, 0, 0, -0x8000000000000000));
  // -1 interpreted as 2 ^ 64 - 1
  Expect.equals(-1, uintComputation(0, 0, 0, -1));
}

typedef NativeSenaryOp = ffi.Int64 Function(
    ffi.Int8, ffi.Int16, ffi.Int32, ffi.Uint8, ffi.Uint16, ffi.Uint32);
typedef SenaryOp = int Function(int, int, int, int, int, int);

void testTruncation() {
  SenaryOp sumSmallNumbers = ffiTestFunctions
      .lookupFunction<NativeSenaryOp, SenaryOp>("SumSmallNumbers");

  // TODO(dacoharkes): implement truncation and sign extension in trampolines
  // for values smaller than 32 bits.
  sumSmallNumbers(128, 0, 0, 0, 0, 0);
  sumSmallNumbers(-129, 0, 0, 0, 0, 0);
  sumSmallNumbers(0, 0, 0, 256, 0, 0);
  sumSmallNumbers(0, 0, 0, -1, 0, 0);

  sumSmallNumbers(0, 0x8000, 0, 0, 0, 0);
  sumSmallNumbers(0, 0xFFFFFFFFFFFF7FFF, 0, 0, 0, 0);
  sumSmallNumbers(0, 0, 0, 0, 0x10000, 0);
  sumSmallNumbers(0, 0, 0, 0, -1, 0);

  Expect.equals(0xFFFFFFFF80000000, sumSmallNumbers(0, 0, 0x80000000, 0, 0, 0));
  Expect.equals(
      0x000000007FFFFFFF, sumSmallNumbers(0, 0, 0xFFFFFFFF7FFFFFFF, 0, 0, 0));
  Expect.equals(0, sumSmallNumbers(0, 0, 0, 0, 0, 0x100000000));
  Expect.equals(0xFFFFFFFF, sumSmallNumbers(0, 0, 0, 0, 0, -1));
}

typedef NativeDoubleUnaryOp = ffi.Double Function(ffi.Double);
typedef DoubleUnaryOp = double Function(double);

void testNativeFunctionDoubles() {
  DoubleUnaryOp times1_337Double = ffiTestFunctions
      .lookupFunction<NativeDoubleUnaryOp, DoubleUnaryOp>("Times1_337Double");
  Expect.approxEquals(2.0 * 1.337, times1_337Double(2.0));
}

typedef NativeFloatUnaryOp = ffi.Float Function(ffi.Float);

void testNativeFunctionFloats() {
  DoubleUnaryOp times1_337Float = ffiTestFunctions
      .lookupFunction<NativeFloatUnaryOp, DoubleUnaryOp>("Times1_337Float");
  Expect.approxEquals(1337.0, times1_337Float(1000.0));
}

typedef NativeOctenaryOp = ffi.IntPtr Function(
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr,
    ffi.IntPtr);
typedef OctenaryOp = int Function(
    int, int, int, int, int, int, int, int, int, int);

void testNativeFunctionManyArguments1() {
  OctenaryOp sumManyInts = ffiTestFunctions
      .lookupFunction<NativeOctenaryOp, OctenaryOp>("SumManyInts");
  Expect.equals(55, sumManyInts(1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
}

typedef NativeDoubleOctenaryOp = ffi.Double Function(
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double);
typedef DoubleOctenaryOp = double Function(double, double, double, double,
    double, double, double, double, double, double);

void testNativeFunctionManyArguments2() {
  DoubleOctenaryOp sumManyDoubles =
      ffiTestFunctions.lookupFunction<NativeDoubleOctenaryOp, DoubleOctenaryOp>(
          "SumManyDoubles");
  Expect.approxEquals(
      55.0, sumManyDoubles(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0));
}

typedef NativeVigesimalOp = ffi.Double Function(
    ffi.IntPtr,
    ffi.Float,
    ffi.IntPtr,
    ffi.Double,
    ffi.IntPtr,
    ffi.Float,
    ffi.IntPtr,
    ffi.Double,
    ffi.IntPtr,
    ffi.Float,
    ffi.IntPtr,
    ffi.Double,
    ffi.IntPtr,
    ffi.Float,
    ffi.IntPtr,
    ffi.Double,
    ffi.IntPtr,
    ffi.Float,
    ffi.IntPtr,
    ffi.Double);
typedef VigesimalOp = double Function(
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double);

void testNativeFunctionManyArguments3() {
  VigesimalOp sumManyNumbers = ffiTestFunctions
      .lookupFunction<NativeVigesimalOp, VigesimalOp>("SumManyNumbers");
  Expect.approxEquals(
      210.0,
      sumManyNumbers(1, 2.0, 3, 4.0, 5, 6.0, 7, 8.0, 9, 10.0, 11, 12.0, 13,
          14.0, 15, 16.0, 17, 18.0, 19, 20.0));
}

typedef Int64PointerUnOp = ffi.Pointer<ffi.Int64> Function(
    ffi.Pointer<ffi.Int64>);

void testNativeFunctionPointer() {
  Int64PointerUnOp assign1337Index1 = ffiTestFunctions
      .lookupFunction<Int64PointerUnOp, Int64PointerUnOp>("Assign1337Index1");
  ffi.Pointer<ffi.Int64> p2 = ffi.allocate(count: 2);
  p2.store(42);
  p2.elementAt(1).store(1000);
  ffi.Pointer<ffi.Int64> result = assign1337Index1(p2);
  Expect.equals(1337, result.load<int>());
  Expect.equals(1337, p2.elementAt(1).load<int>());
  Expect.equals(p2.elementAt(1).address, result.address);
  p2.free();
}

void testNullInt() {
  BinaryOp sumPlus42 =
      ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");

  Expect.throws(() => sumPlus42(43, null));
}

void testNullDouble() {
  DoubleUnaryOp times1_337Double = ffiTestFunctions
      .lookupFunction<NativeDoubleUnaryOp, DoubleUnaryOp>("Times1_337Double");
  Expect.throws(() => times1_337Double(null));
}

void testNullManyArgs() {
  VigesimalOp sumManyNumbers = ffiTestFunctions
      .lookupFunction<NativeVigesimalOp, VigesimalOp>("SumManyNumbers");
  Expect.throws(() => sumManyNumbers(1, 2.0, 3, 4.0, 5, 6.0, 7, 8.0, 9, 10.0,
      11, 12.0, 13, 14.0, 15, 16.0, 17, 18.0, null, 20.0));
}

void testNullPointers() {
  Int64PointerUnOp nullableInt64ElemAt1 =
      ffiTestFunctions.lookupFunction<Int64PointerUnOp, Int64PointerUnOp>(
          "NullableInt64ElemAt1");

  ffi.Pointer<ffi.Int64> result = nullableInt64ElemAt1(null);
  Expect.isNull(result);

  ffi.Pointer<ffi.Int64> p2 = ffi.allocate(count: 2);
  result = nullableInt64ElemAt1(p2);
  Expect.isNotNull(result);
  p2.free();
}

typedef NativeFloatPointerToBool = ffi.Uint8 Function(ffi.Pointer<ffi.Float>);
typedef FloatPointerToBool = int Function(ffi.Pointer<ffi.Float>);

void testFloatRounding() {
  FloatPointerToBool isRoughly1337 = ffiTestFunctions.lookupFunction<
      NativeFloatPointerToBool, FloatPointerToBool>("IsRoughly1337");

  ffi.Pointer<ffi.Float> p2 = ffi.allocate();
  p2.store(1337.0);

  int result = isRoughly1337(p2);
  Expect.equals(1, result);

  p2.free();
}

typedef NativeFloatToVoid = ffi.Void Function(ffi.Float);
typedef DoubleToVoid = void Function(double);

void testVoidReturn() {
  DoubleToVoid devNullFloat = ffiTestFunctions
      .lookupFunction<NativeFloatToVoid, DoubleToVoid>("DevNullFloat");

  devNullFloat(1337.0);

  dynamic loseSignature = devNullFloat;
  dynamic result = loseSignature(1337.0);
  Expect.isNull(result);
}

typedef NativeVoidToFloat = ffi.Float Function();
typedef VoidToDouble = double Function();

void testNoArgs() {
  VoidToDouble inventFloatValue = ffiTestFunctions
      .lookupFunction<NativeVoidToFloat, VoidToDouble>("InventFloatValue");

  double result = inventFloatValue();
  Expect.approxEquals(1337.0, result);
}
