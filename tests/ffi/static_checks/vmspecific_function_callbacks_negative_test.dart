// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers with callbacks.

// dart format off

import 'dart:ffi';

final testLibrary = DynamicLibrary.process();

// Correct type of exceptionalReturn argument to Pointer.fromFunction.
double testExceptionalReturn() {
  Pointer.fromFunction<Double Function()>(returnVoid, null);
  //                                      ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Undefined name 'returnVoid'.
  // [cfe] fromFunction expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.
  Pointer.fromFunction<Void Function()>(returnVoid, 0);
  //                                    ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Undefined name 'returnVoid'.
  // [cfe] fromFunction expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, "abc");
  //                                                             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  // [cfe] Expected 'String' to be a subtype of 'double'.
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, 0);
  //                                                             ^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  // [cfe] Expected 'int' to be a subtype of 'double'.
  Pointer.fromFunction<Double Function()>(testExceptionalReturn);
  //      ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_EXCEPTION_VALUE
  // [cfe] Expected an exceptional return value for a native callback returning 'double'.

  return 0.0; // not used
}

void main() {
  testExceptionalReturn();
}
