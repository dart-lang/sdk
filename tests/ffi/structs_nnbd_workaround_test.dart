// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing getters/setters in structs rather than fields.
//
// VMOptions=--deterministic --optimization-counter-threshold=50

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

import 'coordinate_nnbd_workaround.dart';

void main() {
  for (int i = 0; i < 100; i++) {
    testStructAllocate();
    testStructFromAddress();
    testStructWithNulls();
    testTypeTest();
    testUtf8();
  }
}

/// allocates each coordinate separately in c memory
void testStructAllocate() {
  final c1 = calloc<Coordinate>()
    ..ref.x = 10.0
    ..ref.y = 10.0;
  final c2 = calloc<Coordinate>()
    ..ref.x = 20.0
    ..ref.y = 20.0
    ..ref.next = c1;
  final c3 = calloc<Coordinate>()
    ..ref.x = 30.0
    ..ref.y = 30.0
    ..ref.next = c2;
  c1.ref.next = c3;

  Coordinate currentCoordinate = c1.ref;
  Expect.equals(10.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next.ref;
  Expect.equals(30.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next.ref;
  Expect.equals(20.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next.ref;
  Expect.equals(10.0, currentCoordinate.x);

  calloc.free(c1);
  calloc.free(c2);
  calloc.free(c3);
}

/// allocates coordinates consecutively in c memory
void testStructFromAddress() {
  Pointer<Coordinate> c1 = calloc(3);
  Pointer<Coordinate> c2 = c1.elementAt(1);
  Pointer<Coordinate> c3 = c1.elementAt(2);
  c1.ref
    ..x = 10.0
    ..y = 10.0
    ..next = c3;
  c2.ref
    ..x = 20.0
    ..y = 20.0
    ..next = c1;
  c3.ref
    ..x = 30.0
    ..y = 30.0
    ..next = c2;

  Coordinate currentCoordinate = c1.ref;
  Expect.equals(10.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next.ref;
  Expect.equals(30.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next.ref;
  Expect.equals(20.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next.ref;
  Expect.equals(10.0, currentCoordinate.x);

  calloc.free(c1);
}

void testStructWithNulls() {
  final coordinate = calloc<Coordinate>()
    ..ref.x = 10.0
    ..ref.y = 10.0;
  Expect.equals(coordinate.ref.next, nullptr);
  coordinate.ref.next = coordinate;
  Expect.notEquals(coordinate.ref.next, nullptr);
  coordinate.ref.next = nullptr;
  Expect.equals(coordinate.ref.next, nullptr);
  calloc.free(coordinate);
}

void testTypeTest() {
  final pointer = calloc<Coordinate>();
  Coordinate c = pointer.ref;
  Expect.isTrue(c is Struct);
  calloc.free(pointer);
}

void testUtf8() {
  final String test = 'Hasta Mañana';
  final Pointer<Utf8> medium = test.toNativeUtf8();
  Expect.equals(test, medium.toDartString());
  calloc.free(medium);
}
