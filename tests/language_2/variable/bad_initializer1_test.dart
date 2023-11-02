// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Variable initializer must not reference the initialized variable.

main() {
  const elems = const [
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RECURSIVE_COMPILE_TIME_CONSTANT
    const [
      1,
      2.0,
      true,
      false,
      0xffffffffff,
      elems
//    ^^^^^
// [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
// [cfe] Local variable 'elems' can't be referenced before it is declared.
// [cfe] Undefined name 'elems'.
    ],
    "a",
    "b"
  ];
}
