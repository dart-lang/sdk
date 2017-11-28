// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A dollar must be followed by a "{" or an identifier.

class StringInterpolation3NegativeTest {
  static testMain() {
    // Dollar followed by a number.
    print('F;P4;F$2R'); //# 01: syntax error
  }
}

main() {
  StringInterpolation3NegativeTest.testMain();
}
