// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

// VMOptions=--enable-experiment=records

import 'dylib_utils.dart';

import 'dart:ffi';

import 'package:ffi/ffi.dart';

void main() {
  final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

  // Try to lookup a symbol that exists, but don't use it.
  // With both valid and invalid C signatures.

  print(ffiTestFunctions.lookupFunction<
    Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32)>),
    void Function(Pointer<Utf8>, int, int)>('PassObjectToC'));

  // Error: a named record field.
  print(ffiTestFunctions.lookupFunction< //# 1: compile-time error
    Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32, {Int32 foo})>), //# 1: compile-time error
    void Function(Pointer<Utf8>, int, int)>('PassObjectToC')); //# 1: compile-time error

  // Error: VarArgs not last.
  print(ffiTestFunctions.lookupFunction< //# 2: compile-time error
    Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32)>, Int32), //# 2: compile-time error
    void Function(Pointer<Utf8>, int, int, int)>('PassObjectToC')); //# 2: compile-time error
}
