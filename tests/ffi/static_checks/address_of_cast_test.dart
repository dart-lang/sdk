// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

@Native<Void Function(Pointer<Void>)>()
external void myNativeNonLeaf(Pointer<Void> buffer);

@Native<Void Function(Pointer<Void>)>(isLeaf: true)
external void myNative(Pointer<Void> buffer);

void testTypedData() {
  final buffer = Int32List.fromList([1, 2]);

  myNativeNonLeaf(buffer.address.cast()); //# 01: compile-time error
  myNative(buffer.address); //# 02: compile-time error
}

void testStructField() {
  final myStruct = Struct.create<MyStruct>();
  myNativeNonLeaf(myStruct.arr.address.cast()); //# 03: compile-time error
  myNative(myStruct.arr.address); //# 04: compile-time error
  ;
}

void testUnionField() {
  final myUnion = Union.create<MyUnion>();
  myNativeNonLeaf(myUnion.arr.address.cast()); //# 05: compile-time error
  myNative(myUnion.arr.address); //# 06: compile-time error
  ;
}

void main() {
  testTypedData();
  testStructField();
  testUnionField();
}

final class MyStruct extends Struct {
  @Array(2)
  external Array<Int32> arr;
}

final class MyUnion extends Union {
  @Array(2)
  external Array<Int32> arr;
}
