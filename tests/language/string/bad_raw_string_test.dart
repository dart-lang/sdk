// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  // Raw String may not contain newline (may not be multi-line).
  String x = ''
    r'
//  ^
// [cfe] String starting with r' must end with '.
//   ^
// [analyzer] SYNTACTIC_ERROR.UNTERMINATED_STRING_LITERAL
'
// [error line 13, column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.UNTERMINATED_STRING_LITERAL
// [cfe] String starting with ' must end with '.
    r"
//  ^
// [cfe] String starting with r" must end with ".
//   ^
// [analyzer] SYNTACTIC_ERROR.UNTERMINATED_STRING_LITERAL
"
// [error line 22, column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.UNTERMINATED_STRING_LITERAL
// [cfe] String starting with " must end with ".

      // Test that a raw string containing just one character, a \n char, fails.
      // Enclose the test string in a bigger multiline string, except in case 03:
    '''
      """
    '''
    r'
//  ^
// [cfe] String starting with r' must end with '.
//   ^
// [analyzer] SYNTACTIC_ERROR.UNTERMINATED_STRING_LITERAL
'
// [error line 37, column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.UNTERMINATED_STRING_LITERAL
// [cfe] String starting with ' must end with '.
    '''
    """
    '''
      ;
}
