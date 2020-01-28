// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi calls argument passing.
//
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=10
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100
// VMOptions=--write-protect-code --no-dual-map-code
// VMOptions=--write-protect-code --no-dual-map-code --use-slow-path
// VMOptions=--write-protect-code --no-dual-map-code --stacktrace-every=100
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'dylib_utils.dart';

import "package:expect/expect.dart";

void main() {
  for (int i = 0; i < 100; ++i) {
    testSumVeryManySmallInts();
    testSumVeryManyFloatsDoubles();
  }
}

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

VeryManyIntsOp sumVeryManySmallInts =
    ffiTestFunctions.lookupFunction<NativeVeryManyIntsOp, VeryManyIntsOp>(
        "SumVeryManySmallInts");
// Very many small integers, tests alignment on stack.
void testSumVeryManySmallInts() {
  Expect.equals(
      40 * 41 / 2,
      sumVeryManySmallInts(
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
          20,
          21,
          22,
          23,
          24,
          25,
          26,
          27,
          28,
          29,
          30,
          31,
          32,
          33,
          34,
          35,
          36,
          37,
          38,
          39,
          40));
}

VeryManyFloatsDoublesOp sumVeryManyFloatsDoubles = ffiTestFunctions
    .lookupFunction<NativeVeryManyFloatsDoublesOp, VeryManyFloatsDoublesOp>(
        "SumVeryManyFloatsDoubles");

// Very many floating points, tests alignment on stack, and packing in
// floating point registers in hardfp.
void testSumVeryManyFloatsDoubles() {
  Expect.approxEquals(
      40.0 * 41.0 / 2.0,
      sumVeryManyFloatsDoubles(
          1.0,
          2.0,
          3.0,
          4.0,
          5.0,
          6.0,
          7.0,
          8.0,
          9.0,
          10.0,
          11.0,
          12.0,
          13.0,
          14.0,
          15.0,
          16.0,
          17.0,
          18.0,
          19.0,
          20.0,
          21.0,
          22.0,
          23.0,
          24.0,
          25.0,
          26.0,
          27.0,
          28.0,
          29.0,
          30.0,
          31.0,
          32.0,
          33.0,
          34.0,
          35.0,
          36.0,
          37.0,
          38.0,
          39.0,
          40.0));
}

typedef NativeVeryManyIntsOp = Int16 Function(
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16);

typedef VeryManyIntsOp = int Function(
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int);

typedef NativeVeryManyFloatsDoublesOp = Double Function(
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double);

typedef VeryManyFloatsDoublesOp = double Function(
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double,
    double);
