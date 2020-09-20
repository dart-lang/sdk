// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
// [cfe] 'case' can't be used as an identifier because it's a keyword.
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
// [cfe] Expected ';' after this.
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Getter not found: 'case'.
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_STATEMENT
//       ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//          ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//          ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got ':'.
//          ^
// [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
// [cfe] Unexpected token ':'.
      while (false) {
        break L;
      }
      i++;
  }
}
