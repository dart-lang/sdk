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

// In-body declaring constructor
class C5 {
  int? x;
  this(covariant this.x);
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C6 {
  int x;
  this({covariant this.x});
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C7 {
  int x;
  this({required covariant this.x});
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C8 {
  int? x;
  this([covariant this.x]);
  //   ^
  // [analyzer] unspecified
  // [cfe] unspecified
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

// In-body declaring constructor
class C13 extends A {
  this(covariant super.x);
  //  ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C14 extends A {
  this({covariant super.x});
  //  ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C15 extends A {
  this({required covariant super.x});
  //  ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C16 extends A {
  this([covariant super.x]);
  //  ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
