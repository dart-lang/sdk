// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers with struct
// arguments.
//
// SharedObjects=ffi_test_functions

// @dart = 2.9

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

import 'coordinate.dart';
import 'dylib_utils.dart';
import 'very_large_struct.dart';

typedef NativeCoordinateOp = Pointer<Coordinate> Function(Pointer<Coordinate>);

void main() {
  for (final isLeaf in [false, true]) {
    testFunctionWithStruct(isLeaf: isLeaf);
    testFunctionWithStructArray(isLeaf: isLeaf);
    testFunctionWithVeryLargeStruct(isLeaf: isLeaf);
  }
}

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

/// pass a struct to a c function and get a struct as return value
void testFunctionWithStruct({bool isLeaf: false}) {
  Pointer<NativeFunction<NativeCoordinateOp>> p1 =
      ffiTestFunctions.lookup("TransposeCoordinate");
  NativeCoordinateOp f1 =
      (isLeaf ? p1.asFunction(isLeaf: true) : p1.asFunction(isLeaf: false));

  final c1 = calloc<Coordinate>()
    ..ref.x = 10.0
    ..ref.y = 20.0;
  final c2 = calloc<Coordinate>()
    ..ref.x = 42.0
    ..ref.y = 84.0
    ..ref.next = c1;
  c1.ref.next = c2;

  Coordinate result = f1(c1).ref;

  Expect.approxEquals(20.0, c1.ref.x);
  Expect.approxEquals(30.0, c1.ref.y);

  Expect.approxEquals(42.0, result.x);
  Expect.approxEquals(84.0, result.y);

  calloc.free(c1);
  calloc.free(c2);
}

/// pass an array of structs to a c funtion
void testFunctionWithStructArray({bool isLeaf: false}) {
  Pointer<NativeFunction<NativeCoordinateOp>> p1 =
      ffiTestFunctions.lookup("CoordinateElemAt1");
  NativeCoordinateOp f1 =
      (isLeaf ? p1.asFunction(isLeaf: true) : p1.asFunction(isLeaf: false));

  final coordinateArray = calloc<Coordinate>(3);
  Coordinate c1 = coordinateArray[0];
  Coordinate c2 = coordinateArray[1];
  Coordinate c3 = coordinateArray[2];
  c1.x = 10.0;
  c1.y = 10.0;
  c1.next = coordinateArray.elementAt(2);
  c2.x = 20.0;
  c2.y = 20.0;
  c2.next = coordinateArray.elementAt(0);
  c3.x = 30.0;
  c3.y = 30.0;
  c3.next = coordinateArray.elementAt(1);

  Coordinate result = f1(coordinateArray.elementAt(0)).ref;
  Expect.approxEquals(20.0, result.x);
  Expect.approxEquals(20.0, result.y);

  calloc.free(coordinateArray);
}

typedef VeryLargeStructSum = int Function(Pointer<VeryLargeStruct>);
typedef NativeVeryLargeStructSum = Int64 Function(Pointer<VeryLargeStruct>);

void testFunctionWithVeryLargeStruct({bool isLeaf: false}) {
  Pointer<NativeFunction<NativeVeryLargeStructSum>> p1 =
      ffiTestFunctions.lookup("SumVeryLargeStruct");
  VeryLargeStructSum f =
      (isLeaf ? p1.asFunction(isLeaf: true) : p1.asFunction(isLeaf: false));

  final vlsArray = calloc<VeryLargeStruct>(2);
  VeryLargeStruct vls1 = vlsArray[0];
  VeryLargeStruct vls2 = vlsArray[1];
  List<VeryLargeStruct> structs = [vls1, vls2];
  for (VeryLargeStruct struct in structs) {
    struct.a = 1;
    struct.b = 2;
    struct.c = 4;
    struct.d = 8;
    struct.e = 16;
    struct.f = 32;
    struct.g = 64;
    struct.h = 128;
    struct.i = 256;
    struct.j = 512;
    struct.k = 1024;
    struct.smallLastField = 1;
  }
  vls1.parent = vlsArray.elementAt(1);
  vls1.numChildren = 2;
  vls1.children = vlsArray.elementAt(0);
  vls2.parent = vlsArray.elementAt(1);
  vls2.parent = nullptr;
  vls2.numChildren = 0;
  vls2.children = nullptr;

  int result = f(vlsArray.elementAt(0));
  Expect.equals(2051, result);

  result = f(vlsArray.elementAt(1));
  Expect.equals(2048, result);

  calloc.free(vlsArray);
}
