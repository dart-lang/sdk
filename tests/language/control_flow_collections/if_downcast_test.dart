// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  var a = <int>[if (true as Object) 1];
  //                ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
  //                     ^
  // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.

  var b = <int, int>{if (true as Object) 1: 1};
  //                     ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
  //                          ^
  // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.

  var c = <int>{if (true as Object) 1};
  //                ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
  //                     ^
  // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
}
