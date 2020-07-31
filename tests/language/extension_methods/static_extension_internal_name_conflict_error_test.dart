// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that errors are given for internal name conflicts in extension methods.

// It is an error to have duplicate type parameter names.
extension E1<T, T> on int {
//              ^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] A type variable can't have the same name as another.
}

extension E2 on int {}

// It is an error to have duplicate extension names.
extension E2 on int {}
//        ^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] 'E2' is already declared in this scope.

class E2 {}
//    ^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] 'E2' is already declared in this scope.

typedef E2 = int Function(int);
//      ^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] 'E2' is already declared in this scope.

void E2(int x) {}
//   ^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] 'E2' is already declared in this scope.

int E2 = 3;
//  ^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] 'E2' is already declared in this scope.

////////////////////////////////////////////////////////////////////
// It is an error to have two static members with the same base name
// unless one is a setter and one is a getter.
//
// The next set of tests check various combinations of member name
// conflicts: first testing that members of the same kind (e.g.
// method/method) induce conflicts for the various combinations of
// static/instance; and then testing that members of different kind (e.g.
// method/getter) induce conflicts for the various combinations of
// static/instance.
////////////////////////////////////////////////////////////////////

// Check static members colliding with static members (of the same kind)
extension E3 on int {
  static int method() => 0;
  static int get property => 1;
  static void set property(int value) {}
  static int field = 3;
  static int field2 = 4;

  static int method() => 0;
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'method' is already declared in this scope.
  static int get property => 1;
  //             ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'property' is already declared in this scope.
  static void set property(int value) {}
  //              ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'property' is already declared in this scope.
  static int field = 3;
  //         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'field' is already declared in this scope.
  static int get field2 => 1;
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'field2' is already declared in this scope.
  static void set field2(int value) {}
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
}

// Check instance members colliding with instance members (of the same kind).
extension E4 on int {
  int method() => 0;
  int get property => 1;
  void set property(int value) {}

  int method() => 0;
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'method' is already declared in this scope.
  int get property => 1;
  //      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'property' is already declared in this scope.
  void set property(int value) {}
  //       ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'property' is already declared in this scope.
}

// Check static members colliding with static members (of the same kind).
extension E5 on int {
  static int method() => 0;
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  static int get property => 1;
  //             ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  static void set property(int value) {}
  //              ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  static int get property2 => 1;
  //             ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] Conflicts with setter 'property2'.
  static void set property3(int x) {}
  //              ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] Conflicts with member 'property3'.
  static int field = 3;
  //         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] Conflicts with setter 'field'.
  static int field2 = 3;
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE

  int method() => 0;
  //  ^
  // [cfe] 'method' is already declared in this scope.
  int get property => 1;
  //      ^
  // [cfe] 'property' is already declared in this scope.
  void set property(int value) {}
  //       ^
  // [cfe] 'property' is already declared in this scope.
  void set property2(int value) {}
  //       ^
  // [cfe] Conflicts with member 'property2'.
  int get property3 => 1;
  //      ^
  // [cfe] Conflicts with setter 'property3'.
  void set field(int value) {}
  //       ^
  // [cfe] Conflicts with member 'field'.
  int get field2 => 1;
  //      ^
  // [cfe] 'field2' is already declared in this scope.
}

// Check a static method colliding with a static getter.
extension E6 on int {
  static int method() => 0;
  static int get method => 1;
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'method' is already declared in this scope.
}

// Check a static method colliding with a static setter.
extension E7 on int {
  static int method() => 0;
  //         ^
  // [cfe] Conflicts with setter 'method'.
  static void set method(int value) {}
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] Conflicts with member 'method'.
}

// Check a static method colliding with a static field.
extension E8 on int {
  static int method() => 0;
  static int method = 3;
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'method' is already declared in this scope.
}

// Check an instance method colliding with an instance getter.
extension E9 on int {
  int method() => 0;
  int get method => 1;
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'method' is already declared in this scope.
}

// Check an instance method colliding with an instance setter.
extension E10 on int {
  int method() => 0;
  //  ^
  // [cfe] Conflicts with setter 'method'.
  void set method(int value) {}
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] Conflicts with member 'method'.
}

// Check a static method colliding with an instance getter.
extension E11 on int {
  static int method() => 0;
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  int get method => 1;
  //      ^
  // [cfe] 'method' is already declared in this scope.
}

// Check a static method colliding with an instance setter.
extension E12 on int {
  static int method() => 0;
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] Conflicts with setter 'method'.
  void set method(int value) {}
  //       ^
  // [cfe] Conflicts with member 'method'.
}

// Check an instance method colliding with a static getter.
extension E13 on int {
  int method() => 0;
  static int get method => 1;
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] 'method' is already declared in this scope.
}

// Check an instance method colliding with a static setter.
extension E14 on int {
  int method() => 0;
  //  ^
  // [cfe] Conflicts with setter 'method'.
  static void set method(int value) {}
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] Conflicts with member 'method'.
}

// Check an instance method colliding with a static field.
extension E15 on int {
  int method() => 0;
  static int method = 3;
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] 'method' is already declared in this scope.
}

void main() {}
