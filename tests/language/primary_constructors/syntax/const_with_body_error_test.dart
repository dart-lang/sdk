// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A compile-time error occurs if a class, mixin class, enum, or extension type
// has a constant primary constructor which has a body part that has a body.

// SharedOptions=--enable-experiment=primary-constructors

class const A() {
  this {}
//     ^
// [analyzer] COMPILE_TIME_ERROR.CONST_PRIMARY_CONSTRUCTOR_WITH_BODY
// [cfe] A const constructor can't have a body.
}

mixin class const M() {
  this {}
//     ^
// [analyzer] COMPILE_TIME_ERROR.CONST_PRIMARY_CONSTRUCTOR_WITH_BODY
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_NON_TRIVIAL_GENERATIVE_CONSTRUCTOR
// [cfe] A const constructor can't have a body.
// [cfe] Can't use 'M' as a mixin because it has constructors.
}

enum E(int x) {
  e(1);
  // [error column 3]
  // [cfe] A const constructor can't have a body.
  this {}
//     ^
// [analyzer] COMPILE_TIME_ERROR.CONST_PRIMARY_CONSTRUCTOR_WITH_BODY
// [cfe] A const constructor can't have a body.
}

extension type const Ext(int x) {
  this {}
//     ^
// [analyzer] COMPILE_TIME_ERROR.CONST_PRIMARY_CONSTRUCTOR_WITH_BODY
// [cfe] A const constructor can't have a body.
}
