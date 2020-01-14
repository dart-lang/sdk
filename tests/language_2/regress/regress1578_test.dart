// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 1578.

]~<)$
// [error line 7, column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got ']'.
// [error line 7, column 2, length 1]
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got '~'.
//^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got '<'.
// ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got ')'.
//  ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//  ^
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
