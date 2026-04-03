// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=primary-constructors

class A() {
  this async {}
//     ^^^^^
// [analyzer] SYNTACTIC_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITH_MODIFIER
// [cfe] unspecified
}

class B() {
  this async* {}
//     ^^^^^
// [analyzer] SYNTACTIC_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITH_MODIFIER
// [cfe] unspecified
}

class C() {
  this sync* {}
//     ^^^^
// [analyzer] SYNTACTIC_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITH_MODIFIER
// [cfe] unspecified
}

enum E() {
  v;
  this async {}
//     ^^^^^
// [analyzer] SYNTACTIC_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITH_MODIFIER
//           ^
// [analyzer] COMPILE_TIME_ERROR.CONST_PRIMARY_CONSTRUCTOR_WITH_BODY
// [cfe] unspecified
}

extension type ET(int x) {
  this async {}
//     ^^^^^
// [analyzer] SYNTACTIC_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITH_MODIFIER
// [cfe] unspecified
}
