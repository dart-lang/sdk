// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

@Native<Int32 Function(Pointer<Void>)>(
    symbol: "SumFirstTwoElements", isLeaf: true)
external int sumFirstTwoElements(Pointer<Void> a);

void testStructField() {
  final myStruct = Struct.create<MyStruct>();

  myStruct.arr1[0] = 3424;
  myStruct.arr2[1] = 1000;

  final firstResult = sumFirstTwoElements(myStruct.arr1.address.cast());
  final firstExpected = myStruct.arr1[0] + myStruct.arr1[1];
  Expect.equals(firstResult, firstExpected);

  myStruct.arr2[0] = 10;
  myStruct.arr2[1] = 100001;

  final secondResult = sumFirstTwoElements(myStruct.arr2.address.cast());
  final secondExpected = myStruct.arr2[0] + myStruct.arr2[1];
  Expect.equals(secondResult, secondExpected);
}

void testUnionField() {
  final myUnion = Union.create<MyUnion>();

  myUnion.arr[0] = 23422;
  myUnion.arr[1] = 231312;

  final result = sumFirstTwoElements(myUnion.address.cast());
  final expected = myUnion.arr[0] + myUnion.arr[1];
  Expect.equals(result, expected);
}

void testTypedData() {
  final buffer = Int32List.fromList([34241, 42432, 42313]);
  final result = sumFirstTwoElements(buffer.address.cast());
  final expected = buffer[0] + buffer[1];
  Expect.equals(result, expected);
}

void main() {
  dlopenGlobalPlatformSpecific("ffi_test_functions");
  testStructField();
  testTypedData();
  testUnionField();
}

final class MyStruct extends Struct {
  @Array<Int32>(2)
  external Array<Int32> arr1;

  @Array<Int32>(2)
  external Array<Int32> arr2;
}

final class MyUnion extends Union {
  @Array<Int32>(2)
  external Array<Int32> arr;
}
