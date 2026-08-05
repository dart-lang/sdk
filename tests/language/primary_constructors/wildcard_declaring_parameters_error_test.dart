// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// --------------------
// Declaring parameters named `_` cannot be declared multiple times in a primary
// constructor.

class CMultiple(var int _, var int _);
//                                 ^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] '_' is already declared in this scope.

class DMultiple(final int _, final int _);
//                                     ^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] '_' is already declared in this scope.

enum EnumMultiple(final int _, final int _) {
  //                                     ^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] '_' is already declared in this scope.
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
  // [cfe] Can't access 'this' in a field initializer to read '_'.

  this : assert(_ > 0);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] Can't access 'this' in a field initializer to read '_'.
}

class D(final int _) {
  int x = _;
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] Can't access 'this' in a field initializer to read '_'.

  this : assert(_ > 0);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] Can't access 'this' in a field initializer to read '_'.
}

class E(int _, int _) {
  int x = _;
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Undefined name '_'.

  this : assert(_ > 0);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Undefined name '_'.
}

enum E1(final int _) {
  // ^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST
  e(1);

  final int x = _;
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] Can't access 'this' in a field initializer to read '_'.

  this : assert(_ > 0);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  // [cfe] Can't access 'this' in a field initializer to read '_'.
}

extension type Ext(int _) {
  this : assert(_ > 0);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] Can't access 'this' in a field initializer to read '_'.
}
