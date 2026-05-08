// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A compile-time error occurs if a class, mixin class, enum, or extension type
// declares a primary constructor whose name is `C.n`, and the body declares a
// static member whose basename is `n`.

// SharedOptions=--enable-experiment=primary-constructors

class C1.name() {
//       ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER
  static int name = 1;
  //         ^
  // [cfe] The member conflicts with constructor 'C1.name'.
}

class C2.name() {
//       ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER
  static int get name => 1;
  //             ^
  // [cfe] The member conflicts with constructor 'C2.name'.
}

class C3.name() {
//       ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER
  static void set name(int x) {}
  //              ^
  // [cfe] The member conflicts with constructor 'C3.name'.
}

class C4.name() {
//       ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER
  static void name() {}
  //          ^
  // [cfe] The member conflicts with constructor 'C4.name'.
}

mixin class M1.name() {
//             ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER
  static int name = 1;
  //         ^
  // [cfe] The member conflicts with constructor 'M1.name'.
}

enum E1.name() {
//      ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER
  e.name();
  static int name = 1;
  //         ^
  // [cfe] The member conflicts with constructor 'E1.name'.
}

extension type ET1.name(int x) {
//                 ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER
  static int name = 1;
  //         ^
  // [cfe] The member conflicts with constructor 'ET1.name'.
}
