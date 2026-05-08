// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `out` and `inout` are built-in identifiers.They cannot be used as names in
// declarations.

// SharedOptions=--enable-experiment=variance

class A<out> {}
//      ^
// [analyzer] unspecified
// [cfe] unspecified

class B<inout> {}
//      ^
// [analyzer] unspecified
// [cfe] unspecified

class C<out, inout> {}
//      ^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] unspecified
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] unspecified

F<inout, out>() {}
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] unspecified
//       ^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] unspecified

mixin G<out, inout> {}
//      ^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] unspecified
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] unspecified

class I<out out> {}
//          ^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] unspecified

class J<out inout> {}
//          ^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] unspecified

typedef H<inout, out> = out Function(inout);
//        ^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] unspecified
//               ^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] unspecified

class out {}
//    ^
// [analyzer] unspecified
// [cfe] unspecified

class inout {}
//    ^
// [analyzer] unspecified
// [cfe] unspecified
