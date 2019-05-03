// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;

import 'dylib_utils.dart';

import 'coordinate.dart';

typedef NativeCoordinateOp = Coordinate Function(Coordinate);

main(List<String> arguments) {
  print('start main');

  ffi.DynamicLibrary ffiTestFunctions =
      dlopenPlatformSpecific("ffi_test_functions");

  {
    // pass a struct to a c function and get a struct as return value
    ffi.Pointer<ffi.NativeFunction<NativeCoordinateOp>> p1 =
        ffiTestFunctions.lookup("TransposeCoordinate");
    NativeCoordinateOp f1 = p1.asFunction();

    Coordinate c1 = Coordinate(10.0, 20.0, null);
    Coordinate c2 = Coordinate(42.0, 84.0, c1);
    c1.next = c2;

    Coordinate result = f1(c1);

    print(c1.x);
    print(c1.y);

    print(result.runtimeType);

    print(result.x);
    print(result.y);
  }

  {
    // pass an array of structs to a c funtion
    ffi.Pointer<ffi.NativeFunction<NativeCoordinateOp>> p1 =
        ffiTestFunctions.lookup("CoordinateElemAt1");
    NativeCoordinateOp f1 = p1.asFunction();

    Coordinate c1 = Coordinate.allocate(count: 3);
    Coordinate c2 = c1.elementAt(1);
    Coordinate c3 = c1.elementAt(2);
    c1.x = 10.0;
    c1.y = 10.0;
    c1.next = c3;
    c2.x = 20.0;
    c2.y = 20.0;
    c2.next = c1;
    c3.x = 30.0;
    c3.y = 30.0;
    c3.next = c2;

    Coordinate result = f1(c1);

    print(result.x);
    print(result.y);
  }

  print("end main");
}
