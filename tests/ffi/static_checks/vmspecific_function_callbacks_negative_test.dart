// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers with callbacks.

// Formatting can break multitests, so don't format them.
// dart format off

import 'dart:ffi';

final testLibrary = DynamicLibrary.process();

// Correct type of exceptionalReturn argument to Pointer.fromFunction.
double testExceptionalReturn() {
  Pointer.fromFunction<Double Function()>(returnVoid, null);
//                                         ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'void Function()' can't be assigned to the parameter type 'double Function()'.
  Pointer.fromFunction<Void Function()>(returnVoid, 0);
//                                                   ^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'int' can't be assigned to the parameter type 'void'.
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, "abc");
//                                                               ^^^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'String' can't be assigned to the parameter type 'double'.
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, 0);
//                                                               ^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'int' can't be assigned to the parameter type 'double'.
  Pointer.fromFunction<Double Function()>(testExceptionalReturn);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MISSING_REQUIRED_ARGUMENT
// [cfe] Required argument 'exceptionalReturn' must be provided.

  return 0.0; // not used
}

void main() {
  testExceptionalReturn();
}
