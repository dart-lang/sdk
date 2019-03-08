// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers with callbacks.

library FfiTest;

import 'dart:ffi' as ffi;

import 'dylib_utils.dart';

import "package:expect/expect.dart";

import 'coordinate.dart';

typedef NativeCoordinateOp = Coordinate Function(Coordinate);

typedef CoordinateTrice = Coordinate Function(
    ffi.Pointer<ffi.NativeFunction<NativeCoordinateOp>>, Coordinate);

void main() {
  testFunctionWithFunctionPointer();
  testNativeFunctionWithFunctionPointer();
  testFromFunction();
}

ffi.DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

/// pass a pointer to a c function as an argument to a c function
void testFunctionWithFunctionPointer() {
  ffi.Pointer<ffi.NativeFunction<NativeCoordinateOp>>
      transposeCoordinatePointer =
      ffiTestFunctions.lookup("TransposeCoordinate");

  ffi.Pointer<ffi.NativeFunction<CoordinateTrice>> p2 =
      ffiTestFunctions.lookup("CoordinateUnOpTrice");
  CoordinateTrice coordinateUnOpTrice = p2.asFunction();

  Coordinate c1 = Coordinate(10.0, 20.0, null);
  c1.next = c1;

  Coordinate result = coordinateUnOpTrice(transposeCoordinatePointer, c1);

  print(result.runtimeType);
  print(result.x);
  print(result.y);

  c1.free();
}

typedef BinaryOp = int Function(int, int);

typedef NativeIntptrBinOp = ffi.IntPtr Function(ffi.IntPtr, ffi.IntPtr);

typedef NativeIntptrBinOpLookup
    = ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOp>> Function();

void testNativeFunctionWithFunctionPointer() {
  ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOpLookup>> p1 =
      ffiTestFunctions.lookup("IntptrAdditionClosure");
  NativeIntptrBinOpLookup intptrAdditionClosure = p1.asFunction();

  ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOp>> intptrAdditionPointer =
      intptrAdditionClosure();
  BinaryOp intptrAddition = intptrAdditionPointer.asFunction();
  Expect.equals(37, intptrAddition(10, 27));
}

int myPlus(int a, int b) => a + b;

typedef NativeApplyTo42And74Type = ffi.IntPtr Function(
    ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOp>>);

typedef ApplyTo42And74Type = int Function(
    ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOp>>);

void testFromFunction() {
  ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOp>> pointer =
      ffi.fromFunction(myPlus);
  Expect.isNotNull(pointer);

  ffi.Pointer<ffi.NativeFunction<NativeApplyTo42And74Type>> p17 =
      ffiTestFunctions.lookup("ApplyTo42And74");
  ApplyTo42And74Type applyTo42And74 = p17.asFunction();

  // TODO(dacoharkes): implement this

  // int result = applyTo42And74(pointer);
  // print(result);
}
