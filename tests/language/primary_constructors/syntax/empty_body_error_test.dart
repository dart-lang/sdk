// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Enums that have an empty body (i.e. `;`) can be parsed, but will cause a
// compile-time error when there's no enum constant declared.

enum E1;
//   ^^
// [analyzer] COMPILE_TIME_ERROR.ENUM_WITHOUT_CONSTANTS
// [cfe] An enum declaration can't be empty.

enum E2(final int x);
//   ^^
// [analyzer] COMPILE_TIME_ERROR.ENUM_WITHOUT_CONSTANTS
// [cfe] An enum declaration can't be empty.

enum const E3;
//   ^^^^^
// [analyzer] SYNTACTIC_ERROR.CONST_WITHOUT_PRIMARY_CONSTRUCTOR
// [cfe] 'const' can only be used together with a primary constructor declaration.
//         ^^
// [analyzer] COMPILE_TIME_ERROR.ENUM_WITHOUT_CONSTANTS
// [cfe] An enum declaration can't be empty.

enum const E4(final int x);
//         ^^
// [analyzer] COMPILE_TIME_ERROR.ENUM_WITHOUT_CONSTANTS
// [cfe] An enum declaration can't be empty.

// Mixin application classes cannot have an explicit (empty) class body.

class S;
mixin M on S;
class C = S with M {}
//               ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//                 ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got '{'.

class I;
class C2 = S with M implements I {}
//                             ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//                               ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a declaration, but got '{'.
