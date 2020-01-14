// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that 'dynamic' can be used in const expressions and has the expected
// behavior.

import "package:expect/expect.dart";

const d = dynamic;
const i = int;

void main() {
  Expect.isTrue(identical(d, dynamic));
  // Duplicate key error.
  Expect.equals(1, const { d: 1, d: 2 }.length);
  //               ^
  // [cfe] Constant evaluation error:
  //                             ^
  // [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP
  Expect.equals(2, const { d: 1, i: 2 }.length);
}
