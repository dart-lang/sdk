// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
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

  myNativeNonLeaf(buffer.address.cast());
  //                     ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
  myNative(buffer.address);
  //       ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //              ^^^^^^^
  // [cfe] The argument type 'Pointer<Int32>' can't be assigned to the parameter type 'Pointer<Void>'.
}

void testStructField() {
  final myStruct = Struct.create<MyStruct>();
  myNativeNonLeaf(myStruct.arr.address.cast());
  //                           ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
  myNative(myStruct.arr.address);
  //       ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                    ^^^^^^^
  // [cfe] The argument type 'Pointer<Int32>' can't be assigned to the parameter type 'Pointer<Void>'.

  myNativeNonLeaf(myStruct.value.address.cast());
  //                             ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.

  myNative(myStruct.value.address.cast<Int32>());
  //       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                              ^^^^^^^^^^^^^
  // [cfe] The argument type 'Pointer<Int32>' can't be assigned to the parameter type 'Pointer<Void>'.
}

void testUnionField() {
  final myUnion = Union.create<MyUnion>();
  myNativeNonLeaf(myUnion.arr.address.cast());
  //                          ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.

  myNative(myUnion.arr.address);
  //       ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                   ^^^^^^^
  // [cfe] The argument type 'Pointer<Int32>' can't be assigned to the parameter type 'Pointer<Void>'.

  myNativeNonLeaf(myUnion.value.address.cast());
  //                            ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.

  myNative(myUnion.value.address.cast<Int32>());
  //       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                             ^^^^^^^^^^^^^
  // [cfe] The argument type 'Pointer<Int32>' can't be assigned to the parameter type 'Pointer<Void>'.
}

void main() {
  testTypedData();
  testStructField();
  testUnionField();
}

final class MyStruct extends Struct {
  @Int32()
  external int value;
  @Array(2)
  external Array<Int32> arr;
}

final class MyUnion extends Union {
  @Int32()
  external int value;
  @Array(2)
  external Array<Int32> arr;
}
