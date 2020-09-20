// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final int x = 'foo';
//            ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
const int y = 'foo';
//            ^^^^^
// [analyzer] COMPILE_TIME_ERROR.VARIABLE_TYPE_MISMATCH
// [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
//            ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
int z = 'foo';
//      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.

main() {
  print(x);
  print(y);
  print(z);
}
