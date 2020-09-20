// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that we expect a class after an 'is'.
class A {}

main() {
  var a = A();
  if (a is "A") return 0;
  // [error line 10, column 12, length 0]
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_UNDEFINED_NAME
  // [cfe] Expected ')' before this.
  //       ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected a type, but got '"A"'.
  //       ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TYPE_NAME
  // [cfe] This couldn't be parsed.
}
