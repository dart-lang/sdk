// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error for a formal parameter to be both `covariant` and `final`.

class C1(covariant final int x);
//       ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.

class C2({covariant final int? x = 1});
//        ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.

class C3({required covariant final int x});
//                 ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.

class C4([covariant final int? x]);
//        ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.

extension type E1(covariant final int x);
//                ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.

extension type E2(covariant int x);
//                ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.
