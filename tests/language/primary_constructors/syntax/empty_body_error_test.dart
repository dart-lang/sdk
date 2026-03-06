// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Enums that have an empty body (i.e. `;`) can be parsed, but will cause a
// compile-time error when there's no enum constant declared.

// SharedOptions=--enable-experiment=primary-constructors

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
