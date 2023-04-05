// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns

// Test that attempting to use `case`, `default`, `:`, and `;` tokens in a
// switch expression doesn't confuse the parser.

f(x) => switch (x) {
  case 1: 'one';
//^^^^
// [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
// [cfe] Unexpected token 'case'.
//      ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected '=>' before this.
//             ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.
  case 2: 'two';
//^^^^
// [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
// [cfe] Unexpected token 'case'.
//      ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected '=>' before this.
//             ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.
  default: 'three';
//^^^^^^^
// [analyzer] SYNTACTIC_ERROR.DEFAULT_IN_SWITCH_EXPRESSION
// [cfe] A switch expression may not use the `default` keyword.
//       ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected '=>' before this.
//                ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.
};

main() {}
