// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to make sure we catch assignments to final local variables.

main() {
  final x = 30;
  x = 0;
//^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
// [cfe] Can't assign to the final variable 'x'.
  x += 1;
//^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
// [cfe] Can't assign to the final variable 'x'.
  ++x;
  //^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
  // [cfe] Can't assign to the final variable 'x'.
  x++;
//^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
// [cfe] Can't assign to the final variable 'x'.
}
