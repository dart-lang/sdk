// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test reporting a compile-time error if case expressions do not all have
// the same type or are of type double.

import "package:expect/expect.dart";

void main() {
  Expect.equals("IV", caesarSays(4));
  Expect.equals(null, caesarSays(2));
  Expect.equals(null, archimedesSays(3.14));
}

caesarSays(n) {
  switch (n) {
    case 1:
      return "I";
    case 4:
      return "IV";
    case "M":
    //   ^^^
    // [analyzer] COMPILE_TIME_ERROR.INCONSISTENT_CASE_EXPRESSION_TYPES
      return 1000;
  }
  return null;
}

archimedesSays(n) {
  switch (n) {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS
    case 3.14:
      return "Pi";
    case 2.71828:
      return "Huh?";
  }
  return null;
}
