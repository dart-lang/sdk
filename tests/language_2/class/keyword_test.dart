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
// [analyzer] STATIC_WARNING.UNDEFINED_IDENTIFIER
// [cfe] Expected an identifier, but got 'class'.
//    ^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Setter not found: 'class'.
  print("$class");
  //      ^^^^^
  // [analyzer] STATIC_WARNING.UNDEFINED_IDENTIFIER
  // [cfe] Expected an identifier, but got 'class'.
  //      ^^^^^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Getter not found: 'class'.
}
