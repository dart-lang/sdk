// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=digit-separators

import "package:expect/expect.dart";

main() {
  Object x;
  // Integers.
  x = 100_;
  //  ^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 100___;
  //  ^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER

  // Hexadecimal.
  x = 0x_00;
  //  ^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 0x___00;
  //  ^^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 0x00_;
  //  ^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 0x00___;
  //  ^^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 0_x00;
  //  ^^^^^
  // [cfe] Expected ';' after this.
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //    ^
  // [cfe] Undefined name 'x00'.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  //  ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN

  // Doubles.
  x = 3.14_;
  //  ^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 3.14___;
  //  ^^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 3_.14;
  //  ^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 3___.14;
  //  ^^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 3._14;
  //    ^
  // [cfe] The getter '_14' isn't defined for the class 'int'.
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  x = 3.___14;
  //    ^^^
  // [cfe] The getter '___14' isn't defined for the class 'int'.
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER

  // Exponent notation.
  x = 1e3_;
  //  ^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1e3___;
  //  ^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1e_3;
  //  ^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1e___3;
  //  ^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1e_+3;
  //  ^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1e___+3;
  //  ^^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1e+_3;
  //  ^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1e+___3;
  //  ^^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1_e3;
  //  ^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1___e3;
  //  ^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1.2e3_;
  //  ^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1.2e3___;
  //  ^^^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1.2e_3;
  //  ^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1.2e___3;
  //  ^^^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = .0e_+3;
  //  ^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = .0e___+3;
  //  ^^^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1.2_e3;
  //  ^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  x = 1.2___e3;
  //  ^^^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER

  x = 1._0e-1;
  //    ^^^
  // [cfe] The getter '_0e' isn't defined for the class 'int'.
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
}
