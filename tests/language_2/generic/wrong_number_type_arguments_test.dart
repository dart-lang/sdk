// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Map takes 2 type arguments.
Map<String> foo;
// [error line 8, column 1, length 11]
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
// [cfe] Expected 2 type arguments.
Map<String> baz;
// [error line 12, column 1, length 11]
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
// [cfe] Expected 2 type arguments.

main() {
  foo = null;
  var bar = new Map<String>();
  //            ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
  // [cfe] Expected 2 type arguments.
  baz = new Map();
}
