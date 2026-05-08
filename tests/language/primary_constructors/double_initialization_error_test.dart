// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A compile-time error occurs if an instance variable declaration has an
// initializing expression, and it is also initialized by an element in the
// initializer list of the body part, or by an initializing formal parameter
// of the primary constructor.

// SharedOptions=--enable-experiment=primary-constructors

class C1(this.x) {
//            ^
// [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZED_IN_DECLARATION_AND_PARAMETER_OF_PRIMARY_CONSTRUCTOR
// [cfe] Fields can't be initialized in both the primary constructor parameter list and at their declaration.
  int x = 1;
}

class C2() {
  int x = 1;
  this : x = 2;
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZED_IN_DECLARATION_AND_INITIALIZER_OF_PRIMARY_CONSTRUCTOR
  // [cfe] Fields can't be initialized in both the primary constructor and at their declaration.
}

class C3(this.x) {
  int x;
  this : x = 2;
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER
  //       ^
  // [cfe] 'x' was already initialized by this constructor.
}
