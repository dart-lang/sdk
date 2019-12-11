// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that newlines cannot be escaped in strings.

main() {
  // Note: The newline inside a string literal doesn't play nice with the
  // static error updater tool, so if you need to tweak the static error
  // expectations in this test, you may need to do so manually.
  print('Hello, World!\
');
// [error line 11, column 8, length 1]
// [cfe] Can't find ')' to match '('.
// [error line 11, column 9, length 1]
// [cfe] String starting with ' must end with '.
// [error line 11, column 23, length 1]
// [analyzer] SYNTACTIC_ERROR.INVALID_UNICODE_ESCAPE
// [cfe] An escape sequence starting with '\u' must be followed by 4 hexadecimal digits or from 1 to 6 digits between '{' and '}'.
// [error line 11, column 23, length 1]
// [analyzer] SYNTACTIC_ERROR.UNTERMINATED_STRING_LITERAL
// [error line 12, column 1, length 3]
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// [error line 12, column 1]
// [cfe] String starting with ' must end with '.
// [error line 12, column 3, length 1]
// [analyzer] SYNTACTIC_ERROR.UNTERMINATED_STRING_LITERAL
}
// [error line 29, column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
