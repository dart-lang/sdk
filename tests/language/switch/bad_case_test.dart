// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test reporting a compile-time error if case expressions are of type double.

import "package:expect/expect.dart";

void main() {
  Expect.equals("IV", caesarSays(4));
  Expect.equals(null, caesarSays(2));
  Expect.equals(null, archimedesSays(3.14));
}

/// Before null safety, it was an error if the cases in a switch were not of
/// the same type, regardless of the value expression's type. Now it is only an
/// error if the cases are not a subtype of the value's type.
caesarSays(n) {
  switch (n) {
    case 1:
      return "I";
    case 4:
      return "IV";
    case "M":
      return 1000;
  }
  return null;
}

archimedesSays(n) {
  switch (n) {
    case 3.14:
    //   ^^^^
    // [analyzer] COMPILE_TIME_ERROR.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS
    // [cfe] Case expression '3.14' does not have a primitive operator '=='.
      return "Pi";
    case 2.71828:
    //   ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS
    // [cfe] Case expression '2.71828' does not have a primitive operator '=='.
      return "Huh?";
  }
  return null;
}
