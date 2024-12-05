// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  0x10as;
//^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//     ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 's'.
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
  bool _1 = false; // An identifier can start with an underscore and then contain only numbers.
}
