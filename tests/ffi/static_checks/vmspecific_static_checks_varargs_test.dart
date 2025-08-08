// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'package:ffi/ffi.dart';

void main() {
  final ffiTestFunctions = DynamicLibrary.process();

  // Error: a named record field.
  print(ffiTestFunctions.lookupFunction<
    Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32, {Int32 foo})>),
//                                                      ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.VARARGS_CANNOT_HAVE_NAMED_FIELDS
// [cfe] VarArgs cannot have named arguments.
    void Function(Pointer<Utf8>, int, int)>('PassObjectToC'));

  // Error: VarArgs not last.
  print(ffiTestFunctions.lookupFunction<
    Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32)>, Int32),
//                               ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.VARARGS_MUST_BE_LAST_PARAMETER
// [cfe] VarArgs must be the last parameter.
    void Function(Pointer<Utf8>, int, int, int)>('PassObjectToC'));
}
