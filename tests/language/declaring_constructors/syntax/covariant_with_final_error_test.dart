// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error for a formal parameter to be both `covariant` and `final`.

// SharedOptions=--enable-experiment=declaring-constructors

class C1(covariant final int x);
//      ^
// [analyzer] unspecified
// [cfe] unspecified

class C2({covariant final int? x = 1});
//      ^
// [analyzer] unspecified
// [cfe] unspecified

class C3({required covariant final int x});
//      ^
// [analyzer] unspecified
// [cfe] unspecified

class C4([covariant final int? x]);
//      ^
// [analyzer] unspecified
// [cfe] unspecified

class C5 {
  this(covariant final int x);
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C6 {
  this({covariant final int? x});
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C7 {
  this({required covariant final int x});
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C8 {
  this([covariant final int? x]);
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type E1(covariant final int x);
//                ^
// [analyzer] unspecified
// [cfe] unspecified

extension type E2(covariant int x);
//                ^
// [analyzer] unspecified
// [cfe] unspecified
