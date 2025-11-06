// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error for a formal parameter to have the `covariant` modifier
// but not the `var` modifier.

// SharedOptions=--enable-experiment=declaring-constructors

class C1(covariant int x);
//      ^
// [analyzer] unspecified
// [cfe] unspecified

class C2({covariant int? x});
//      ^
// [analyzer] unspecified
// [cfe] unspecified

class C3({required covariant int x});
//      ^
// [analyzer] unspecified
// [cfe] unspecified

class C4([covariant int? x]);
//      ^
// [analyzer] unspecified
// [cfe] unspecified
