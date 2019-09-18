// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that since `variance` flag is disabled, correct variance modifier usage will issue an error.

class A<in X> {}
//      ^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME
// [cfe] Expected an identifier, but got 'in'.
//      ^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
//         ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.

class B<out X, in Y, inout Z> {}
//          ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.
//             ^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME
// [cfe] Expected an identifier, but got 'in'.
//             ^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
//                ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.
//                         ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.

mixin C<inout T> {}
//            ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.

typedef D<out T> = T Function();
//            ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.
