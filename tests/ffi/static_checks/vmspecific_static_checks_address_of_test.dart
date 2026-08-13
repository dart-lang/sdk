// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi extra checks
//
// SharedObjects=ffi_test_dynamic_library ffi_test_functions

import 'dart:ffi';

void main() {
  testUnsupportedAddress();
}

void testUnsupportedAddress() {
  myNative(4.address);
  //         ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_RECEIVER
  // [cfe] The receiver of '.address' must be a concrete 'TypedData', a concrete 'TypedData' '[]', an 'Array', an 'Array' '[]', a Struct field, or a Union field.

  final myStruct = Struct.create<MyStruct>();
  myStruct.address;
  //       ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.

  myNativeNoLeaf(myStruct.a.address);
  //                        ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
}

@Native<Int8 Function(Pointer<Int8>)>(isLeaf: true)
external int myNative(Pointer<Int8> pointer);

@Native<Int8 Function(Pointer<Int8>)>()
external int myNativeNoLeaf(Pointer<Int8> pointer);

final class MyStruct extends Struct {
  @Int8()
  external int a;
}
