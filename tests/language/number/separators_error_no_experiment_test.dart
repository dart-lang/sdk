// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 3.4

main() {
  Object x;
  // TODO(srawlins): The text of the expectations below is expected to change,
  // when the experiment is turned on by default.
  x = 1__000_000_000;
  //  ^^^^^^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  x = 555_867_5309;
  //  ^^^^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  x = -1_000_000;
  //   ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  x = 00_1_00;
  //  ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  x = -00_99;
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  x = 0__0__0__0__0;
  //  ^^^^^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.

  // Integers.
  x = 100_;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.

  // Hexadecimal.
  x = 0x_00;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.

  // Doubles.
  x = 3_.14;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  x = 3._14;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter '_14' isn't defined for the type 'int'.

  // Exponent notation.
  x = 1e_3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  x = 1_e3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  x = 1.2e_3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.
  x = 1.2_e3;
  //  ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_SEPARATOR_IN_NUMBER
  //  ^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] Digit separators ('_') in a number literal can only be placed between two digits.
  // [cfe] This requires the experimental 'digit-separators' language feature to be enabled.

  x = 1._0e-1;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter '_0e' isn't defined for the type 'int'.
}
