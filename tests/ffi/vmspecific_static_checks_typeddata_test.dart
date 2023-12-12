// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi extra checks
//
// SharedObjects=ffi_test_dynamic_library ffi_test_functions

import 'dart:ffi';
import 'dart:typed_data';

import 'dylib_utils.dart';

void main() {}

final testLibrary = dlopenPlatformSpecific("ffi_test_functions");

final unwrapInt8List = testLibrary.lookupFunction<
    Int8 Function(Pointer<Int8>, Int64),
    int Function(Int8List, int)>('UnwrapInt8List', isLeaf: true);

final unwrapFloat64List = testLibrary.lookupFunction<
    Int8 Function(Pointer<Double>, Int64),
    int Function(Float64List, int)>('UnwrapFloat64List', isLeaf: true);

final unwrapFloat32List = testLibrary.lookupFunction<
    Int8 Function(Pointer<Float>, Int64),
    int Function(Float32List, int)>('UnwrapFloat32List', isLeaf: true);

final typedDataInHandle = testLibrary.lookupFunction<
    Int8 Function(Handle, Int64),
    int Function(Int8List, int)>('TypedDataInHandle');

final unwrapInt8List2 = testLibrary.lookupFunction<
//                                  ^
// [cfe] FFI non-leaf calls can't take typed data arguments.
    Int8 Function(Pointer<Int8>, Int64),
    int Function(Int8List, int)>('UnwrapInt8List');
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_LEAF_CALL_MUST_NOT_TAKE_TYPED_DATA

final unwrapInt8List3 = testLibrary.lookupFunction<
//                                  ^
// [cfe] Expected type 'int Function(Int8List, int)' to be 'int Function(Pointer<Uint64>, int)', which is the Dart type corresponding to 'NativeFunction<Int8 Function(Pointer<Uint64>, Int64)>'.
    Int8 Function(Pointer<Uint64>, Int64),
    int Function(Int8List, int)>('UnwrapInt8List', isLeaf: true);
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE

final unwrapInt8List4 = testLibrary.lookupFunction<
//                                  ^
// [cfe] Expected type 'int Function(Float32List, int)' to be 'int Function(Pointer<Int8>, int)', which is the Dart type corresponding to 'NativeFunction<Int8 Function(Pointer<Int8>, Int64)>'.
    Int8 Function(Pointer<Int8>, Int64),
    int Function(Float32List, int)>('UnwrapInt8List', isLeaf: true);
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE

@Native<Int8 Function(Pointer<Int8>, Int64)>(
    symbol: 'UnwrapInt8List', isLeaf: true)
external int unwrapInt8List5(Int8List list, int length);

final unwrapInt8List7 =
    testLibrary.lookupFunction<Pointer<Int8> Function(), Int8List Function()>(
  //            ^
  // [cfe] FFI calls can't return typed data.
  //                                                     ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CALL_MUST_NOT_RETURN_TYPED_DATA
  'UnwrapInt8List',
);

external int f1(Int8List i);

void g1() {
  Pointer.fromFunction<Int8 Function(Pointer<Int8>)>(f1, 5);
  //      ^
  // [cfe] FFI callbacks can't take typed data arguments or return value.
  //                                                 ^^
  // [analyzer] COMPILE_TIME_ERROR.CALLBACK_MUST_NOT_USE_TYPED_DATA

  Pointer.fromFunction<Int8 Function(Handle)>(f1, 5);
}

external Int8List f2(int i);

void g2() {
  Pointer.fromFunction<Pointer<Int8> Function(Int8)>(f2);
  //      ^
  // [cfe] FFI callbacks can't take typed data arguments or return value.
  //                                                 ^^
  // [analyzer] COMPILE_TIME_ERROR.CALLBACK_MUST_NOT_USE_TYPED_DATA
}

void foo1(Pointer<NativeFunction<Pointer<Uint8> Function()>> p) {
  p.asFunction<Uint8List Function()>(isLeaf: true);
  //^
  // [cfe] FFI calls can't return typed data.
  //           ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CALL_MUST_NOT_RETURN_TYPED_DATA
}

// TODO(https://dartbug.com/54181): Write negative tests for @Natives.
