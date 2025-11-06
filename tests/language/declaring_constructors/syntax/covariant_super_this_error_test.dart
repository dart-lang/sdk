// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A compile-time error occurs if the formal parameter contains a term of the
// form `this.v`, or `super.v` where `v` is an identifier, and the parameter has
// the modifier `covariant`.

// SharedOptions=--enable-experiment=declaring-constructors

// `covariant` with `this.x`

// In-header declaring constructor
class C1(covariant this.x) {
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified
  int x;
}


class C2({covariant this.x}) {
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified
  int? x;
}

class C3({required covariant this.x}) {
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified
  int x;
}

class C4([covariant this.x]) {
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified
  int? x;
}

// `covariant` with `super.x`

class A(final int? x);

// In-header declaring constructor
class C9(covariant super.x) extends A;
//                 ^
// [analyzer] unspecified
// [cfe] unspecified

class C10({covariant super.x}) extends A;
//                        ^
// [analyzer] unspecified
// [cfe] unspecified

class C11({required covariant super.x}) extends A;
//                                ^
// [analyzer] unspecified
// [cfe] unspecified

class C12([covariant super.x]) extends A;
//                           ^
// [analyzer] unspecified
// [cfe] unspecified
