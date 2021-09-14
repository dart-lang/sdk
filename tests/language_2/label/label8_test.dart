// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

main() {
  int i;
  // Grammar doesn't allow label on block for switch statement.
  switch(i)
  //      ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
  // [cfe] A switch statement must have a body, even if it is empty.
    L:
  {
    case 111:
//  ^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_STATEMENT
// [cfe] 'case' can't be used as an identifier because it's a keyword.
// [cfe] Expected ';' after this.
// [cfe] Undefined name 'case'.
//       ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//          ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
// [cfe] Expected an identifier, but got ':'.
// [cfe] Unexpected token ':'.
      while (false) {
        break L;
      }
      i++;
  }
}
