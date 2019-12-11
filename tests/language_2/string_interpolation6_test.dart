// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A dollar must be followed by a "{" or an identifier.

class StringInterpolation6NegativeTest {
  static testMain() {
    // Dollar not followed by "{" or identifier.
    String regexp;
    regexp = "^(\\d\\d?)[-/](\\d\\d?)$";
    //                                ^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
    print(regexp);
  }
}

main() {
  StringInterpolation6NegativeTest.testMain();
}
