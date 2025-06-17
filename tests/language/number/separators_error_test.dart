// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Object x;
  // Integers.
  x = 100_;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 100___;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.

  // Hexadecimal.
  x = 0x_00;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 0x___00;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 0x00_;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 0x00___;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 0_x00;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [cfe] Expected ';' after this.
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Undefined name 'x00'.

  // Doubles.
  x = 3.14_;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 3.14___;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 3_.14;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 3___.14;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 3._14;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter '_14' isn't defined for the type 'int'.
  x = 3.___14;
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter '___14' isn't defined for the type 'int'.

  // Exponent notation.
  x = 1e3_;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1e3___;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1e_3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1e___3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1e_+3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1e___+3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1e+_3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1e+___3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1_e3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1___e3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1.2e3_;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1.2e3___;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1.2e_3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1.2e___3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = .0e_+3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = .0e___+3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1.2_e3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  x = 1.2___e3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.

  x = 1._0e-1;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter '_0e' isn't defined for the type 'int'.
}
