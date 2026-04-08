// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=primary-constructors

class A() {
  this async {}
//     ^^^^^
// [analyzer] SYNTACTIC_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITH_MODIFIER
// [cfe] A primary constructor body can't have the modifier 'async'.
//           ^
// [cfe] Constructor bodies can't use 'async', 'async*', or 'sync*'.
}

class B() {
  this async* {}
//     ^^^^^
// [analyzer] SYNTACTIC_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITH_MODIFIER
// [cfe] A primary constructor body can't have the modifier 'async*'.
//            ^
// [cfe] Constructor bodies can't use 'async', 'async*', or 'sync*'.
}

class C() {
  this sync* {}
//     ^^^^
// [analyzer] SYNTACTIC_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITH_MODIFIER
// [cfe] A primary constructor body can't have the modifier 'sync*'.
//           ^
// [cfe] Constructor bodies can't use 'async', 'async*', or 'sync*'.
}

enum E() {
  v;
  // [error column 3]
  // [cfe] A const constructor can't have a body.
  this async {}
//     ^^^^^
// [analyzer] SYNTACTIC_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITH_MODIFIER
// [cfe] A primary constructor body can't have the modifier 'async'.
//           ^
// [analyzer] COMPILE_TIME_ERROR.CONST_PRIMARY_CONSTRUCTOR_WITH_BODY
// [cfe] A const constructor can't have a body.
// [cfe] Constructor bodies can't use 'async', 'async*', or 'sync*'.
}

extension type ET(int x) {
  this async {}
//     ^^^^^
// [analyzer] SYNTACTIC_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITH_MODIFIER
// [cfe] A primary constructor body can't have the modifier 'async'.
//           ^
// [cfe] Constructor bodies can't use 'async', 'async*', or 'sync*'.
}
