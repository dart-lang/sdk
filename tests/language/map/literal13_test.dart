// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Legacy compound literal syntax that should go away.

main() {
  var map = new Map<int>{ "a": 1, "b": 2, "c": 3 };
  //            ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
  // [cfe] Expected 2 type arguments.
  //                   ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected '(' after this.
  //                    ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                      ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                         ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                         ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Expected an identifier, but got ':'.
  //                         ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
  // [cfe] Unexpected token ':'.
  //                           ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                            ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                            ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Expected an identifier, but got ','.
  //                            ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
  // [cfe] Unexpected token ','.
  //                              ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                                 ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                                 ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Expected an identifier, but got ':'.
  //                                 ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
  // [cfe] Unexpected token ':'.
  //                                   ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                                    ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                                    ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Expected an identifier, but got ','.
  //                                    ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
  // [cfe] Unexpected token ','.
  //                                      ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                                         ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //                                         ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Expected an identifier, but got ':'.
  //                                         ^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
  // [cfe] Unexpected token ':'.
  //                                           ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
}
