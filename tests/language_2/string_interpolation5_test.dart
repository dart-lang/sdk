// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A dollar must be followed by a "{" or an identifier.

class StringInterpolation5NegativeTest {
  static testMain() {
    // Dollar followed by a number.
    print("$1,000");
    //      ^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
  }
}

main() {
  StringInterpolation5NegativeTest.testMain();
}
