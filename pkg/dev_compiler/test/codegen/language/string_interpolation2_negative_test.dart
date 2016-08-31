// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A dollar must be followed by a "{" or an identifier.

class StringInterpolation2NegativeTest {
  testMain() {
    print('C;Y1;X4;K"$/Month"');  // Dollar followed by "/".
  }
}

main() {
  StringInterpolation2NegativeTest.testMain();
}
