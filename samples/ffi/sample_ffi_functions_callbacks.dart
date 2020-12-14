// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'coordinate.dart';
import 'dylib_utils.dart';

typedef NativeCoordinateOp = Pointer<Coordinate> Function(Pointer<Coordinate>);

typedef CoordinateTrice = Pointer<Coordinate> Function(
    Pointer<NativeFunction<NativeCoordinateOp>>, Pointer<Coordinate>);

typedef BinaryOp = int Function(int, int);
typedef NativeIntptrBinOp = IntPtr Function(IntPtr, IntPtr);
typedef NativeIntptrBinOpLookup = Pointer<NativeFunction<NativeIntptrBinOp>>
    Function();

typedef NativeApplyTo42And74Type = IntPtr Function(
    Pointer<NativeFunction<NativeIntptrBinOp>>);

typedef ApplyTo42And74Type = int Function(
    Pointer<NativeFunction<NativeIntptrBinOp>>);

int myPlus(int a, int b) {
  print("myPlus");
  print(a);
  print(b);
  return a + b;
}

main() {
  print('start main');

  DynamicLibrary ffiTestFunctions =
      dlopenPlatformSpecific("ffi_test_functions");

  {
    // Pass a c pointer to a c function as an argument to a c function.
    Pointer<NativeFunction<NativeCoordinateOp>> transposeCoordinatePointer =
        ffiTestFunctions.lookup("TransposeCoordinate");
    Pointer<NativeFunction<CoordinateTrice>> p2 =
        ffiTestFunctions.lookup("CoordinateUnOpTrice");
    CoordinateTrice coordinateUnOpTrice = p2.asFunction();
    Coordinate c1 = Coordinate.allocate(10.0, 20.0, nullptr);
    c1.next = c1.addressOf;
    Coordinate result =
        coordinateUnOpTrice(transposeCoordinatePointer, c1.addressOf).ref;
    print(result.runtimeType);
    print(result.x);
    print(result.y);
  }

  {
    // Return a c pointer to a c function from a c function.
    Pointer<NativeFunction<NativeIntptrBinOpLookup>> p14 =
        ffiTestFunctions.lookup("IntptrAdditionClosure");
    NativeIntptrBinOpLookup intptrAdditionClosure = p14.asFunction();

    Pointer<NativeFunction<NativeIntptrBinOp>> intptrAdditionPointer =
        intptrAdditionClosure();
    BinaryOp intptrAddition = intptrAdditionPointer.asFunction();
    print(intptrAddition(10, 27));
  }

  {
    Pointer<NativeFunction<NativeIntptrBinOp>> pointer =
        Pointer.fromFunction(myPlus, 0);
    print(pointer);

    Pointer<NativeFunction<NativeApplyTo42And74Type>> p17 =
        ffiTestFunctions.lookup("ApplyTo42And74");
    ApplyTo42And74Type applyTo42And74 = p17.asFunction();

    int result = applyTo42And74(pointer);
    print(result);
  }

  print("end main");
}
