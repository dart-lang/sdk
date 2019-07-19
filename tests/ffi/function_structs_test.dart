// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers with struct
// arguments.
//
// SharedObjects=ffi_test_functions

library FfiTest;

import 'dart:ffi' as ffi;
import 'dart:ffi' show Pointer;

import 'dylib_utils.dart';

import "package:expect/expect.dart";

import 'coordinate.dart';
import 'very_large_struct.dart';

typedef NativeCoordinateOp = Pointer<Coordinate> Function(Pointer<Coordinate>);

void main() {
  testFunctionWithStruct();
  testFunctionWithStructArray();
  testFunctionWithVeryLargeStruct();
}

ffi.DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

/// pass a struct to a c function and get a struct as return value
void testFunctionWithStruct() {
  ffi.Pointer<ffi.NativeFunction<NativeCoordinateOp>> p1 =
      ffiTestFunctions.lookup("TransposeCoordinate");
  NativeCoordinateOp f1 = p1.asFunction();

  Pointer<Coordinate> c1 =
      Coordinate.allocate(10.0, 20.0, ffi.nullptr.cast<Coordinate>()).addressOf;
  Pointer<Coordinate> c2 = Coordinate.allocate(42.0, 84.0, c1).addressOf;
  c1.load<Coordinate>().next = c2;

  Coordinate result = f1(c1).load();

  Expect.approxEquals(20.0, c1.load<Coordinate>().x);
  Expect.approxEquals(30.0, c1.load<Coordinate>().y);

  Expect.approxEquals(42.0, result.x);
  Expect.approxEquals(84.0, result.y);

  c1.free();
  c2.free();
}

/// pass an array of structs to a c funtion
void testFunctionWithStructArray() {
  ffi.Pointer<ffi.NativeFunction<NativeCoordinateOp>> p1 =
      ffiTestFunctions.lookup("CoordinateElemAt1");
  NativeCoordinateOp f1 = p1.asFunction();

  Coordinate c1 = Pointer<Coordinate>.allocate(count: 3).load();
  Coordinate c2 = c1.addressOf.elementAt(1).load();
  Coordinate c3 = c1.addressOf.elementAt(2).load();
  c1.x = 10.0;
  c1.y = 10.0;
  c1.next = c3.addressOf;
  c2.x = 20.0;
  c2.y = 20.0;
  c2.next = c1.addressOf;
  c3.x = 30.0;
  c3.y = 30.0;
  c3.next = c2.addressOf;

  Coordinate result = f1(c1.addressOf).load();
  Expect.approxEquals(20.0, result.x);
  Expect.approxEquals(20.0, result.y);

  c1.addressOf.free();
}

typedef VeryLargeStructSum = int Function(Pointer<VeryLargeStruct>);
typedef NativeVeryLargeStructSum = ffi.Int64 Function(Pointer<VeryLargeStruct>);

void testFunctionWithVeryLargeStruct() {
  ffi.Pointer<ffi.NativeFunction<NativeVeryLargeStructSum>> p1 =
      ffiTestFunctions.lookup("SumVeryLargeStruct");
  VeryLargeStructSum f = p1.asFunction();

  VeryLargeStruct vls1 = Pointer<VeryLargeStruct>.allocate(count: 2).load();
  VeryLargeStruct vls2 = vls1.addressOf.elementAt(1).load();
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
  vls1.parent = vls2.addressOf;
  vls1.numChildren = 2;
  vls1.children = vls1.addressOf;
  vls2.parent = vls2.addressOf;
  vls2.parent = ffi.nullptr.cast();
  vls2.numChildren = 0;
  vls2.children = ffi.nullptr.cast();

  int result = f(vls1.addressOf);
  Expect.equals(2051, result);

  result = f(vls2.addressOf);
  Expect.equals(2048, result);

  vls1.addressOf.free();
}
