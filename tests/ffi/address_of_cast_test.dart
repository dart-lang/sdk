// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

// @dart=3.5

import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

// In both below native methods, the expecting parameters are
// SumFirstTwoElements(Pointer<Array<Int32>> (which is also Pointer<Int32>))
// SumTwoElements(a: Pointer<Int32>, b: Pointer<Int32)
// but we are intentionally setting to
// Pointer<Void> to test .address.cast()

@Native<Int32 Function(Pointer<Void>)>(
    symbol: "SumFirstTwoElements", isLeaf: true)
external int sumFirstTwoElements(Pointer<Void> a);

@Native<Int32 Function(Pointer<Void>, Pointer<Void>)>(
    symbol: "SumTwoPointers", isLeaf: true)
external int sumTwoPointers(Pointer<Void> a, Pointer<Void> b);

void testStructField() {
  final myStruct = Struct.create<MyStruct>();

  myStruct.arr1[0] = 3424;
  myStruct.arr2[1] = 1000;

  final expectedArr1 = myStruct.arr1[0] + myStruct.arr1[1];

  final arr1SumFirstTwoElements =
      sumFirstTwoElements(myStruct.arr1.address.cast());
  Expect.equals(arr1SumFirstTwoElements, expectedArr1);

  final arr1SumTwoPointers = sumTwoPointers(
      myStruct.arr1[0].address.cast(), myStruct.arr1[1].address.cast());
  Expect.equals(arr1SumTwoPointers, expectedArr1);

  myStruct.arr2[0] = 10;
  myStruct.arr2[1] = 100001;

  final expectedArr2 = myStruct.arr2[0] + myStruct.arr2[1];

  final arr2SumFirstTwoElements =
      sumFirstTwoElements(myStruct.arr2.address.cast());
  Expect.equals(arr2SumFirstTwoElements, expectedArr2);

  final arr2SumTwoPointers = sumTwoPointers(
      myStruct.arr2[0].address.cast(), myStruct.arr2[1].address.cast());
  Expect.equals(arr2SumTwoPointers, expectedArr2);

  myStruct.value1 = 22;
  myStruct.value2 = 3222;

  final expectedStructValueSum = myStruct.value1 + myStruct.value2;

  final structValueSumTwoPointers = sumTwoPointers(
      myStruct.value1.address.cast(), myStruct.value2.address.cast());
  Expect.equals(structValueSumTwoPointers, expectedStructValueSum);
}

void testUnionField() {
  final myUnion = Union.create<MyUnion>();

  myUnion.arr[0] = 23422;
  myUnion.arr[1] = 231312;

  final expected = myUnion.arr[0] + myUnion.arr[1];

  final arrSumFirstTwoElements =
      sumFirstTwoElements(myUnion.arr.address.cast());
  Expect.equals(arrSumFirstTwoElements, expected);

  final arrSumTwoPointers = sumTwoPointers(
      myUnion.arr[0].address.cast(), myUnion.arr[1].address.cast());
  Expect.equals(arrSumTwoPointers, expected);

  myUnion.value1 = 234522;
  myUnion.value2 = 3322542;

  final expectedStructValueSum = myUnion.value1 + myUnion.value2;
  final structValueSumTwoPointers = sumTwoPointers(
      myUnion.value1.address.cast(), myUnion.value2.address.cast());
  Expect.equals(structValueSumTwoPointers, expectedStructValueSum);
}

void testTypedData() {
  final buffer = Int32List.fromList([34241, 42432, 42313]);
  final expected = buffer[0] + buffer[1];

  final bufferSumFirstTwoElements = sumFirstTwoElements(buffer.address.cast());
  Expect.equals(bufferSumFirstTwoElements, expected);

  final bufferSumFirstTwoPointers =
      sumTwoPointers(buffer[0].address.cast(), buffer[1].address.cast());
  Expect.equals(bufferSumFirstTwoPointers, expected);
}

void main() {
  dlopenGlobalPlatformSpecific("ffi_test_functions");
  testStructField();
  testTypedData();
  testUnionField();
}

final class MyStruct extends Struct {
  @Int32()
  external int value1;

  @Int32()
  external int value2;

  @Array<Int32>(2)
  external Array<Int32> arr1;

  @Array<Int32>(2)
  external Array<Int32> arr2;
}

final class MyUnion extends Union {
  @Int32()
  external int value1;

  @Int32()
  external int value2;

  @Array<Int32>(2)
  external Array<Int32> arr;
}
