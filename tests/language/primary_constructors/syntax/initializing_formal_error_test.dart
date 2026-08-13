// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A compile-time error occurs if a declaration has a primary constructor with
// an initializing formal and no instance variable of the same name.

class C(this.x) {}
//      ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD
//           ^
// [cfe] 'x' isn't an instance field of this class.

enum E(this.x) {
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD
  //        ^
  // [cfe] 'x' isn't an instance field of this class.
  e(1);
}
