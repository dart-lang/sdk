// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing try/catch statement without any exceptions
// being thrown.
// Negative test should fail compilation, illegal throw specifier.

class Helper {
  static int f1(int i) {
    try {
      int j;
      j = 10;
      throw;  // An exception object is needed here.
    } catch (var e) {
      i = 200;
    }
    return i;
  }
}

class TryCatch6NegativeTest {
  static testMain() {
    Expect.equals(1, Helper.f1(1));
  }
}

main() {
  TryCatch6NegativeTest.testMain();
}
