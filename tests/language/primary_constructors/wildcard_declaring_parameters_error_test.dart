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
// [analyzer] unspecified
// [cfe] unspecified

class DMultiple(final int _, final int _);
//                                     ^
// [analyzer] unspecified
// [cfe] unspecified

enum EnumMultiple(final int _, final int _) {
  //                                     ^
  // [analyzer] unspecified
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
  // [analyzer] unspecified
  // [cfe] unspecified

  this : assert(_ > 0);
  //            ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class D(final int _) {
  int x = _;
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  this : assert(_ > 0);
  //            ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class E(int _, int _) {
  int x = _;
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  this : assert(_ > 0);
  //            ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

enum E1(final int _) {
  e(1);

  final int x = _;
  //            ^
  // [analyzer] unspecified
  // [cfe] unspecified

  this : assert(_ > 0);
  //            ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type Ext(int _) {
  this : assert(_ > 0);
  //            ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
