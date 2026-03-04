// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the FFI transformer does not crash when encountering
// a malformed lookupFunction call.
// Regression test for https://github.com/dart-lang/sdk/issues/62693

import 'dart:ffi';

void main() {
  final dll = DynamicLibrary.open("libc.so.6");
  // The following line should report a compilation error for missing argument,
  // and undefined types A and B, but it should NOT crash the compiler.
  final _ = dll.lookupFunction<A, B>();
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
  // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
  // [cfe] 'A' isn't a type.
  //                              ^
  // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
  // [cfe] 'B' isn't a type.
  //                                 ^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
  //                                ^
  // [cfe] Too few positional arguments: 1 required, 0 given.
}
