// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error if a class, enum, or extension type does not have a primary
// constructor, but the body contains a primary constructor body.
// It is also an error to have multiple primary constructor bodies.

// SharedOptions=--enable-experiment=primary-constructors

class C1 {
  this : assert(1 != 2);
  // [error column 3, length 4]
  // [analyzer] COMPILE_TIME_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITHOUT_DECLARATION
  // [cfe] A primary constructor body requires a primary constructor declaration.
}

class C2() {
  this;

  this : assert(1 != 2);
  // [error column 3, length 4]
  // [analyzer] COMPILE_TIME_ERROR.MULTIPLE_PRIMARY_CONSTRUCTOR_BODY_DECLARATIONS
  // [cfe] Only one primary constructor body declaration is allowed.
}

class C3 {
  this;
  // [error column 3, length 4]
  // [analyzer] COMPILE_TIME_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITHOUT_DECLARATION
  // [cfe] A primary constructor body requires a primary constructor declaration.

  this : assert(1 != 2);
  // [error column 3, length 4]
  // [analyzer] COMPILE_TIME_ERROR.MULTIPLE_PRIMARY_CONSTRUCTOR_BODY_DECLARATIONS
  // [analyzer] COMPILE_TIME_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITHOUT_DECLARATION
  // [cfe] Only one primary constructor body declaration is allowed.
}

enum E1 {
  e;
  this : assert(1 != 2);
  // [error column 3, length 4]
  // [analyzer] COMPILE_TIME_ERROR.PRIMARY_CONSTRUCTOR_BODY_WITHOUT_DECLARATION
  // [cfe] A primary constructor body requires a primary constructor declaration.
}

enum E2(int x) {
  e(1);
  this;

  this : assert(x != 2);
  // [error column 3, length 4]
  // [analyzer] COMPILE_TIME_ERROR.MULTIPLE_PRIMARY_CONSTRUCTOR_BODY_DECLARATIONS
  // [cfe] Only one primary constructor body declaration is allowed.
}

extension type ET1(int x) {
  this;

  this : assert(x != 2);
  // [error column 3, length 4]
  // [analyzer] COMPILE_TIME_ERROR.MULTIPLE_PRIMARY_CONSTRUCTOR_BODY_DECLARATIONS
  // [cfe] Only one primary constructor body declaration is allowed.
}
