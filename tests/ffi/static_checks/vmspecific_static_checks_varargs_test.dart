// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart format off

// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'package:ffi/ffi.dart';

void main() {
  final ffiTestFunctions = DynamicLibrary.process();

  // Error: a named record field.
  print(ffiTestFunctions.lookupFunction<
  //                     ^
  // [cfe] Expected type 'NativeFunction<Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32, {Int32 foo})>)>' to be a valid and instantiated subtype of 'NativeType'.
    Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32, {Int32 foo})>),
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
    void Function(Pointer<Utf8>, int, int)>('PassObjectToC'));

  // Error: VarArgs not last.
  print(ffiTestFunctions.lookupFunction<
  //                     ^
  // [cfe] Expected type 'NativeFunction<Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32)>, Int32)>' to be a valid and instantiated subtype of 'NativeType'.
    Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32)>, Int32),
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
    void Function(Pointer<Utf8>, int, int, int)>('PassObjectToC'));
}
