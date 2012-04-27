// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StringCaseTest {

  static testMain() {
    testLowerUpper();
  }

  static testLowerUpper() {
    var a = "Stop! Smell the Roses.";
    var allLower = "stop! smell the roses.";
    var allUpper = "STOP! SMELL THE ROSES.";
    Expect.equals(allUpper, a.toUpperCase());
    Expect.equals(allLower, a.toLowerCase());
  }
}

main() {
  StringCaseTest.testMain();
}
