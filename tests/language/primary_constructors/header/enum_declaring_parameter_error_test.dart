// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An enum cannot declare mutable fields through declaring parameters.

// SharedOptions=--enable-experiment=primary-constructors

enum E1(var int x) {
//     ^
// [cfe] Enum constructors are constant so all fields must be final.
//              ^
// [analyzer] COMPILE_TIME_ERROR.NON_FINAL_FIELD_IN_ENUM

  a(0)
}

enum E2() {
//     ^
// [cfe] Enum constructors are constant so all fields must be final.
  a;

  int x = 0;
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.NON_FINAL_FIELD_IN_ENUM
}
