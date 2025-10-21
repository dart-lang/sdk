// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=declaring-constructors

// Declaring constructors with optional parameters can have default values, but
// they must be constant.

int f() => 0;

class C {
  this([int x = f()]);
  //            ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

enum E {
  e;

  const this([int x = f()]) {}
  //                  ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
