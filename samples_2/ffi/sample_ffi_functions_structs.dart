// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'coordinate.dart';
import 'dylib_utils.dart';

typedef NativeCoordinateOp = Pointer<Coordinate> Function(Pointer<Coordinate>);

main() {
  print('start main');

  DynamicLibrary ffiTestFunctions =
      dlopenPlatformSpecific("ffi_test_functions");

  {
    // Pass a struct to a c function and get a struct as return value.
    Pointer<NativeFunction<NativeCoordinateOp>> p1 =
        ffiTestFunctions.lookup("TransposeCoordinate");
    NativeCoordinateOp f1 = p1.asFunction();

    final c1 = calloc<Coordinate>()
      ..ref.x = 10.0
      ..ref.y = 20.0;
    final c2 = calloc<Coordinate>()
      ..ref.x = 42.0
      ..ref.y = 84.0
      ..ref.next = c1;
    c1.ref.next = c2;

    Coordinate result = f1(c1).ref;

    print(c1.ref.x);
    print(c1.ref.y);

    print(result.runtimeType);

    print(result.x);
    print(result.y);
  }

  {
    // Pass an array of structs to a c funtion.
    Pointer<NativeFunction<NativeCoordinateOp>> p1 =
        ffiTestFunctions.lookup("CoordinateElemAt1");
    NativeCoordinateOp f1 = p1.asFunction();

    Pointer<Coordinate> c1 = calloc<Coordinate>(3);
    Pointer<Coordinate> c2 = c1.elementAt(1);
    Pointer<Coordinate> c3 = c1.elementAt(2);
    c1.ref.x = 10.0;
    c1.ref.y = 10.0;
    c1.ref.next = c3;
    c2.ref.x = 20.0;
    c2.ref.y = 20.0;
    c2.ref.next = c1;
    c3.ref.x = 30.0;
    c3.ref.y = 30.0;
    c3.ref.next = c2;

    Coordinate result = f1(c1).ref;

    print(result.x);
    print(result.y);
  }

  print("end main");
}
