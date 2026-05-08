// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=primary-constructors

// Enums that have an empty body (i.e. `;`) can be parsed, but will cause a
// compile-time error when there's no enum constant declared.

enum E1;
//   ^
// [analyzer] unspecified
// [cfe] unspecified

enum E2(final int x);
//   ^
// [analyzer] unspecified
// [cfe] unspecified

enum const E3;
//   ^
// [analyzer] unspecified
// [cfe] unspecified

enum const E4(final int x);
//   ^
// [analyzer] unspecified
// [cfe] unspecified

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
