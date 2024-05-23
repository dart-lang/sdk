// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Integer literals.
  Expect.isTrue(2 is int);
  //                 ^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_NON_TYPE
  // [cfe] Local variable 'int' can't be referenced before it is declared.
  Expect.equals(2, 2 as int);
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.CAST_TO_NON_TYPE
  // [cfe] Local variable 'int' can't be referenced before it is declared.
  Expect.isTrue(-2 is int);
  //                  ^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_NON_TYPE
  // [cfe] Local variable 'int' can't be referenced before it is declared.
  Expect.equals(-2, -2 as int);
  //                      ^^^
  // [analyzer] COMPILE_TIME_ERROR.CAST_TO_NON_TYPE
  // [cfe] Local variable 'int' can't be referenced before it is declared.
  Expect.isTrue(0x10 is int);
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_NON_TYPE
  // [cfe] Local variable 'int' can't be referenced before it is declared.
  Expect.isTrue(-0x10 is int);
  //                     ^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_NON_TYPE
  // [cfe] Local variable 'int' can't be referenced before it is declared.

  // "a" will be part of hex literal, the following "s" is an error.
  0x10as int;
//^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//     ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CLASS
// [cfe] 's' isn't a type.
  0x;
//^
// [cfe] A hex digit (0-9 or A-F) must follow '0x'.
// ^
// [analyzer] SYNTACTIC_ERROR.MISSING_HEX_DIGIT

  // Double literals.
  1d;
//^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'd'.
  1D;
//^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'D'.
  1.1d;
//^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//   ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'd'.
  1.1D;
//^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//   ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'D'.
  1e;
//^
// [cfe] Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).
// ^
// [analyzer] SYNTACTIC_ERROR.MISSING_DIGIT
  1x;
//^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'x'.
}
