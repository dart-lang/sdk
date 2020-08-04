// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test insures that statically initialized variables, fields, and
// parameters report compile-time errors.

int a = "String";
//      ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.

class A {
  static const int c = "String";
  //                   ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.VARIABLE_TYPE_MISMATCH
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
  //                   ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  final int d = "String";
  //            ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
  int e = "String";
  //      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
  A() {
     int f = "String";
     //      ^^^^^^^^
     // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
     // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
  }
  method(
      [
     int
      g = "String"]) {
      //  ^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
    return g;
  }
}

main() {}
