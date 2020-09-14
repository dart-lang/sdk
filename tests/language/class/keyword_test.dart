// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that "class" cannot be used as identifier.

class foo {}

void main() {
  int class = 10;
//^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//    ^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] 'class' can't be used as an identifier because it's a keyword.
//    ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
// [cfe] Setter not found: 'class'.
  print("$class");
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] 'class' can't be used as an identifier because it's a keyword.
  //      ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] Getter not found: 'class'.
}
