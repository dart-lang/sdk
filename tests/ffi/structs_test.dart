// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi struct pointers.

library FfiTest;

import 'dart:ffi' as ffi;

import "package:expect/expect.dart";

import 'coordinate_bare.dart' as bare;
import 'coordinate_manual.dart' as manual;
import 'coordinate.dart';

void main() {
  testStructAllocate();
  testStructFromAddress();
  testStructWithNulls();
  testBareStruct();
  testManualStruct();
  testTypeTest();
}

/// allocates each coordinate separately in c memory
void testStructAllocate() {
  Coordinate c1 = Coordinate(10.0, 10.0, null);
  Coordinate c2 = Coordinate(20.0, 20.0, c1);
  Coordinate c3 = Coordinate(30.0, 30.0, c2);
  c1.next = c3;

  Coordinate currentCoordinate = c1;
  Expect.equals(10.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(30.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(20.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(10.0, currentCoordinate.x);

  c1.free();
  c2.free();
  c3.free();
}

/// allocates coordinates consecutively in c memory
void testStructFromAddress() {
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

  Coordinate currentCoordinate = c1;
  Expect.equals(10.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(30.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(20.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(10.0, currentCoordinate.x);

  c1.free();
}

void testStructWithNulls() {
  Coordinate coordinate = Coordinate(10.0, 10.0, null);
  Expect.isNull(coordinate.next);
  coordinate.next = coordinate;
  Expect.isNotNull(coordinate.next);
  coordinate.next = null;
  Expect.isNull(coordinate.next);
  coordinate.free();
}

void testBareStruct() {
  int structSize = ffi.sizeOf<ffi.Double>() * 2 + ffi.sizeOf<ffi.IntPtr>();
  bare.Coordinate c1 = ffi.allocate<ffi.Uint8>(count: structSize * 3).cast();
  bare.Coordinate c2 = c1.offsetBy(structSize).cast();
  bare.Coordinate c3 = c1.offsetBy(structSize * 2).cast();
  c1.x = 10.0;
  c1.y = 10.0;
  c1.next = c3;
  c2.x = 20.0;
  c2.y = 20.0;
  c2.next = c1;
  c3.x = 30.0;
  c3.y = 30.0;
  c3.next = c2;

  bare.Coordinate currentCoordinate = c1;
  Expect.equals(10.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(30.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(20.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(10.0, currentCoordinate.x);

  c1.free();
}

void testManualStruct() {
  manual.Coordinate c1 = manual.Coordinate(10.0, 10.0, null);
  manual.Coordinate c2 = manual.Coordinate(20.0, 20.0, c1);
  manual.Coordinate c3 = manual.Coordinate(30.0, 30.0, c2);
  c1.next = c3;

  manual.Coordinate currentCoordinate = c1;
  Expect.equals(10.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(30.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(20.0, currentCoordinate.x);
  currentCoordinate = currentCoordinate.next;
  Expect.equals(10.0, currentCoordinate.x);

  c1.free();
  c2.free();
  c3.free();
}

void testTypeTest() {
  Coordinate c = Coordinate(10, 10, null);
  Expect.isTrue(c is ffi.Pointer);
  Expect.isTrue(c is ffi.Pointer<ffi.Void>);
  c.free();
}
