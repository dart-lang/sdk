// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers with callbacks.



import 'dart:ffi';

final testLibrary = DynamicLibrary.process();

void returnVoid() {}

// Correct type of exceptionalReturn argument to Pointer.fromFunction.
double testExceptionalReturn() {
  Pointer.fromFunction<Double Function()>(returnVoid, null);
  //                                                  ^^^^
  // [cfe] The exceptional return value must be a 'double'.
  // [analyzer] COMPILE_TIME_ERROR.INVALID_EXCEPTION_VALUE

  Pointer.fromFunction<Void Function()>(returnVoid, 0);
  //                                                ^
  // [cfe] The exceptional return value must be 'void'.
  // [analyzer] COMPILE_TIME_ERROR.INVALID_EXCEPTION_VALUE

  Pointer.fromFunction<Double Function()>(testExceptionalReturn, "abc");
  //                                                             ^^^^^
  // [cfe] The exceptional return value must be a 'double'.
  // [analyzer] COMPILE_TIME_ERROR.INVALID_EXCEPTION_VALUE

  Pointer.fromFunction<Double Function()>(testExceptionalReturn, 0);
  //                                                             ^
  // [cfe] The exceptional return value must be a 'double'.
  // [analyzer] COMPILE_TIME_ERROR.INVALID_EXCEPTION_VALUE

  Pointer.fromFunction<Double Function()>(testExceptionalReturn);
  //      ^^^^^^^^^^^^
  // [cfe] The exceptional return value must be a 'double'.
  // [analyzer] COMPILE_TIME_ERROR.MISSING_EXCEPTION_VALUE

  return 0.0; // not used
}

void main() {
  testExceptionalReturn();
}
