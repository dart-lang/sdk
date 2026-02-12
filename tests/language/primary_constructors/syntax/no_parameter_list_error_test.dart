// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error if a class does not have a primary constructor, but the body
// of the class contains a primary constructor body.

// SharedOptions=--enable-experiment=primary-constructors

class C1 {
  this : assert(1 != 2);
  // [error column 3]
  // [cfe] A primary constructor body requires a primary constructor declaration.
  // ^
  // [analyzer] unspecified
}

class C2() {
  this;

  this : assert(1 != 2);
  // [error column 3]
  // [cfe] Only one primary constructor body declaration is allowed.
  // ^
  // [analyzer] unspecified
}

class C3 {
  this;
  // [error column 3]
  // [cfe] A primary constructor body requires a primary constructor declaration.
  // ^
  // [analyzer] unspecified

  this : assert(1 != 2);
  // [error column 3]
  // [cfe] Only one primary constructor body declaration is allowed.
  // ^
  // [analyzer] unspecified
}
