// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A compile-time error occurs if a declaration has a primary constructor with
// an initializing formal and no instance variable of the same name.

// SharedOptions=--enable-experiment=primary-constructors

class C(this.x) {}
//      ^
// [analyzer] unspecified
// [cfe] unspecified

enum E(this.x) {
//     ^
// [analyzer] unspecified
// [cfe] unspecified
  e(1);
}
