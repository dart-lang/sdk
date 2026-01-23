// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'package:ffi/ffi.dart';

void main() {
  final ffiTestFunctions = DynamicLibrary.process();

  // Error: a named record field.
  print(ffiTestFunctions.lookupFunction<
    Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32, {Int32 foo})>),
    void Function(Pointer<Utf8>, int, int)>('PassObjectToC'));
    // [cfe] The type argument for 'VarArgs' must be a record type with only ordinal parameters.
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT

  // Error: VarArgs not last.
  print(ffiTestFunctions.lookupFunction<
    Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32)>, Int32),
    void Function(Pointer<Utf8>, int, int, int)>('PassObjectToC'));
    // [cfe] 'VarArgs' can only be the last parameter of a function type.
    // [analyzer] COMPILE_TIME_ERROR.VARARGS_NOT_LAST
}
