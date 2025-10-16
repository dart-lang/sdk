// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// For mixins, an empty body, `{}`, cannot be replaced by `;`. Enums require a
// non-empty declaration.

// SharedOptions=--enable-experiment=declaring-constructors

class C1;

mixin M1;
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M2 implements C1;
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M3 on C1;
//    ^
// [analyzer] unspecified
// [cfe] unspecified

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
