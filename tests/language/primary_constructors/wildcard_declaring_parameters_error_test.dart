// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=primary-constructors

import 'package:expect/expect.dart';

// --------------------
// Declaring parameters named `_` cannot be declared multiple times in a primary
// constructor.

class CMultiple(var int _, var int _);
//                         ^
// [cfe] unspecified
//                                 ^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION

class DMultiple(final int _, final int _);
//                                     ^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] unspecified

enum EnumMultiple(final int _, final int _) {
  //                                     ^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] unspecified
  e1(1, 2);
}

// --------------------
// Wildcard variables cannot be referenced in the initializing expressions of
// non-late instance variables or in the initializer list of the body part of
// the primary constructor.

class C(var int _) {
  int x = _;
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] unspecified

  this : assert(_ > 0);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] unspecified
}

class D(final int _) {
  int x = _;
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] unspecified

  this : assert(_ > 0);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] unspecified
}

class E(int _, int _) {
  int x = _;
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] unspecified

  this : assert(_ > 0);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] unspecified
}

enum E1(final int _) {
//   ^^
// [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST
  e(1);

  final int x = _;
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] unspecified

  this : assert(_ > 0);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  // [cfe] unspecified
}

extension type Ext(int _) {
  this : assert(_ > 0);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] unspecified
}
