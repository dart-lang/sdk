// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Integer literals.
  Expect.isTrue(2 is int);
  //                 ^^^
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  //                 ^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_NON_TYPE
  Expect.equals(2, 2 as int);
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.CAST_TO_NON_TYPE
  Expect.isTrue(-2 is int);
  //                  ^^^
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  //                  ^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_NON_TYPE
  Expect.equals(-2, -2 as int);
  //                      ^^^
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  //                      ^^^
  // [analyzer] COMPILE_TIME_ERROR.CAST_TO_NON_TYPE
  Expect.isTrue(0x10 is int);
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_NON_TYPE
  Expect.isTrue(-0x10 is int);
  //                     ^^^
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  //                     ^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_NON_TYPE

  // "a" will be part of hex literal, the following "s" is an error.
  0x10as int;
//^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//     ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CLASS
// [cfe] 's' isn't a type.
//       ^
// [cfe] Can't declare 'int' because it was already used in this scope.
  0x;
//^
// [cfe] A hex digit (0-9 or A-F) must follow '0x'.
// ^
// [analyzer] SYNTACTIC_ERROR.MISSING_HEX_DIGIT

  // Double literals.
  Expect.isTrue(2.0 is double);
  Expect.equals(2.0, 2.0 as double);
  Expect.isTrue(-2.0 is double);
  Expect.equals(-2.0, -2.0 as double);
  Expect.isTrue(.2 is double);
  Expect.equals(0.2, .2 as double);
  Expect.isTrue(1e2 is double);
  Expect.equals(1e2, 1e2 as double);
  Expect.isTrue(1e-2 is double);
  Expect.equals(1e-2, 1e-2 as double);
  Expect.isTrue(1e+2 is double);
  Expect.equals(1e+2, 1e+2 as double);
  Expect.throwsNoSuchMethodError(() => 1.e+2);
  //                                     ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'e' isn't defined for the class 'int'.
  1d;
//^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Getter not found: 'd'.
  1D;
//^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Getter not found: 'D'.
  Expect.throwsNoSuchMethodError(() => 1.d+2);
  //                                     ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'd' isn't defined for the class 'int'.
  Expect.throwsNoSuchMethodError(() => 1.D+2);
  //                                     ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'D' isn't defined for the class 'int'.
  1.1d;
//^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//   ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Getter not found: 'd'.
  1.1D;
//^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//   ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Getter not found: 'D'.
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
// [cfe] Getter not found: 'x'.
}
