// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class NumberIdentifierNegativeTest {

  static void testMain() {
    1is int;  // Number literals must not be followed by an identifier or keyword.
  }

}
main() {
  NumberIdentifierNegativeTest.testMain();
}
