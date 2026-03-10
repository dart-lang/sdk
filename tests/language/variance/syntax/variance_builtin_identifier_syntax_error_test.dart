// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `out` and `inout` are built-in identifiers. They cannot be used as type
// names.

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
//      ^
// [analyzer] unspecified
// [cfe] unspecified
//           ^
// [analyzer] unspecified
// [cfe] unspecified

F<inout, out>() {}
//^
// [analyzer] unspecified
// [cfe] unspecified
//       ^
// [analyzer] unspecified
// [cfe] unspecified

mixin G<out, inout> {}
//      ^
// [analyzer] unspecified
// [cfe] unspecified
//           ^
// [analyzer] unspecified
// [cfe] unspecified

typedef H<inout, out> = out Function(inout);
//        ^
// [analyzer] unspecified
// [cfe] unspecified
//               ^
// [analyzer] unspecified
// [cfe] unspecified

class out {}
//    ^
// [analyzer] unspecified
// [cfe] unspecified

class inout {}

//    ^
// [analyzer] unspecified
// [cfe] unspecified
