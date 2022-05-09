// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Test that newlines cannot be escaped in strings.

main() {
  // Note: The newline inside a string literal doesn't play nice with the
  // static error updater tool, so if you need to tweak the static error
  // expectations in this test, you may need to do so manually.
  print('Hello, World!\
  //   ^
  // [cfe] Can't find ')' to match '('.
  //    ^
  // [cfe] String starting with ' must end with '.
  //                  ^
  // [analyzer] SYNTACTIC_ERROR.INVALID_UNICODE_ESCAPE_STARTED
  // [analyzer] SYNTACTIC_ERROR.UNTERMINATED_STRING_LITERAL
  // [cfe] The string '\' can't stand alone.
');
// [error column 1, length 3]
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// [cfe] String starting with ' must end with '.
//^
// [analyzer] SYNTACTIC_ERROR.UNTERMINATED_STRING_LITERAL
}
// [error column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
