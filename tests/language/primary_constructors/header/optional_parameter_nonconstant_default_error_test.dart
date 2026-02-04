// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=primary-constructors

// Tests that declaring constructors with optional parameters cannot have
// non-constant default values in a header declaring constructor.

int f() => 0;

class C([int x = f()]);
  //             ^
  // [analyzer] unspecified
  // [cfe] unspecified

enum E([int x = f()]) {
  //            ^
  // [analyzer] unspecified
  // [cfe] unspecified
  e;
}
