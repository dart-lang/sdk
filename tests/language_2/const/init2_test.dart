// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const intValue = 0;
const double c = 0.0;
const double d = intValue;
//               ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.VARIABLE_TYPE_MISMATCH
// [cfe] A value of type 'int' can't be assigned to a variable of type 'double'.
//               ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

main() {
  print(c);
  print(d);
}
