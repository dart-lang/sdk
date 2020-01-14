// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Variable initializer must not reference the initialized variable.

main() {
  const elems = const [
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RECURSIVE_COMPILE_TIME_CONSTANT
  // [cfe] Can't declare 'elems' because it was already used in this scope.
    const [
      1,
      2.0,
      true,
      false,
      0xffffffffff,
      elems
//    ^^^^^
// [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
// [cfe] Getter not found: 'elems'.
    ],
    "a",
    "b"
  ];
}
