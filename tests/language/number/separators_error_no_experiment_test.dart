// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 3.4

main() {
  Object x;
  // TODO(srawlins): The text of the expectations below is expected to change,
  // when the experiment is turned on by default.
  x = 1__000_000_000;
  //  ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  //  ^^^^^^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  x = 555_867_5309;
  //  ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  //  ^^^^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  x = -1_000_000;
  //   ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  //   ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  x = 00_1_00;
  //  ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  //  ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  x = -00_99;
  //   ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  x = 0__0__0__0__0;
  //  ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  //  ^^^^^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED

  // Integers.
  x = 100_;
  //  ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED

  // Hexadecimal.
  x = 0x_00;
  //  ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED

  // Doubles.
  x = 3_.14;
  //  ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  x = 3._14;
  //    ^
  // [cfe] The getter '_14' isn't defined for the class 'int'.
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER

  // Exponent notation.
  x = 1e_3;
  //  ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  x = 1_e3;
  //  ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  x = 1.2e_3;
  //  ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  x = 1.2_e3;
  //  ^
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^^^
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED

  x = 1._0e-1;
  //    ^^^
  // [cfe] The getter '_0e' isn't defined for the class 'int'.
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
}
