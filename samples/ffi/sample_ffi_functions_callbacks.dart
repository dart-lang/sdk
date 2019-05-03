// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;

import 'dylib_utils.dart';

import 'coordinate.dart';

typedef NativeCoordinateOp = Coordinate Function(Coordinate);

typedef CoordinateTrice = Coordinate Function(
    ffi.Pointer<ffi.NativeFunction<NativeCoordinateOp>>, Coordinate);

typedef BinaryOp = int Function(int, int);
typedef NativeIntptrBinOp = ffi.IntPtr Function(ffi.IntPtr, ffi.IntPtr);
typedef NativeIntptrBinOpLookup
    = ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOp>> Function();

typedef NativeApplyTo42And74Type = ffi.IntPtr Function(
    ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOp>>);

typedef ApplyTo42And74Type = int Function(
    ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOp>>);

int myPlus(int a, int b) {
  print("myPlus");
  print(a);
  print(b);
  return a + b;
}

main(List<String> arguments) {
  print('start main');

  ffi.DynamicLibrary ffiTestFunctions =
      dlopenPlatformSpecific("ffi_test_functions");

  {
    // pass a c pointer to a c function as an argument to a c function
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
  }

  {
    // return a c pointer to a c function from a c function
    ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOpLookup>> p14 =
        ffiTestFunctions.lookup("IntptrAdditionClosure");
    NativeIntptrBinOpLookup intptrAdditionClosure = p14.asFunction();

    ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOp>> intptrAdditionPointer =
        intptrAdditionClosure();
    BinaryOp intptrAddition = intptrAdditionPointer.asFunction();
    print(intptrAddition(10, 27));
  }

  {
    ffi.Pointer<ffi.NativeFunction<NativeIntptrBinOp>> pointer =
        ffi.fromFunction(myPlus);
    print(pointer);

    ffi.Pointer<ffi.NativeFunction<NativeApplyTo42And74Type>> p17 =
        ffiTestFunctions.lookup("ApplyTo42And74");
    ApplyTo42And74Type applyTo42And74 = p17.asFunction();

    // int result = applyTo42And74(pointer);
    // print(result);
  }

  print("end main");
}
