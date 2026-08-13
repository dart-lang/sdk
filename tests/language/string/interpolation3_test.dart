// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A dollar must be followed by a "{" or an identifier.

class StringInterpolation3NegativeTest {
  static testMain() {
    // Dollar followed by a number.
    print('F;P4;F$2R');
    //            ^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  }
}

main() {
  StringInterpolation3NegativeTest.testMain();
}
