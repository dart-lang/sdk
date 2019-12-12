// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers with callbacks.

import 'dart:ffi';

import 'dylib_utils.dart';

final DynamicLibrary testLibrary = dlopenPlatformSpecific("ffi_test_functions");

// Correct type of exceptionalReturn argument to Pointer.fromFunction.
double testExceptionalReturn() {
  Pointer.fromFunction<Double Function()>(returnVoid, null); //# 59: compile-time error
  Pointer.fromFunction<Void Function()>(returnVoid, 0); //# 60: compile-time error
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, "abc"); //# 61: compile-time error
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, 0); //# 62: compile-time error
  Pointer.fromFunction<Double Function()>(testExceptionalReturn); //# 63: compile-time error

  return 0.0; // not used
}

void main() {
  testExceptionalReturn();
}
