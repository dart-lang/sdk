// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing bad named parameters.


class BadNamedParametersTest {

  int f42(int a, [int b = 20, int c = 30]) {
    return 100*(100*a + b) + c;
  }

  int f52(int a, [int b = 20, int c, int d = 40]) {
    return 100*(100*(100*a + b) + (c == null ? 0 : c)) + d;
  }

  static testMain() {
    BadNamedParametersTest np = new BadNamedParametersTest();

    // Verify that NoSuchMethod is called after an error is detected.
    bool caught;
    try {
      caught = false;
      np.f42(10, 25, b:25);  // Parameter b passed twice.
    } catch (NoSuchMethodException e) {
      caught = true;
    }
    Expect.equals(true, caught);
    try {
      caught = false;
      np.f42(10, 25, x:99);  // Parameter x does not exist.
    } catch (NoSuchMethodException e) {
      caught = true;
    }
    Expect.equals(true, caught);
    try {
      caught = false;
      np.f52(10, b:25, b1:99, c:35);  // Parameter b1 does not exist.
    } catch (NoSuchMethodException e) {
      caught = true;
    }
    Expect.equals(true, caught);
    try {
      caught = false;
      np.f42(10, 20, 30, 40);  // Too many parameters.
    } catch (NoSuchMethodException e) {
      caught = true;
    }
    Expect.equals(true, caught);
    try {
      caught = false;
      np.f42(b:25);  // Too few parameters.
    } catch (NoSuchMethodException e) {
      caught = true;
    }
    Expect.equals(true, caught);
  }
}

main() {
  BadNamedParametersTest.testMain();
}
