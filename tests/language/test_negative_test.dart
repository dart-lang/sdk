// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program which has a syntax error. This test is to
// ensure that the resulting parse error message is correctly
// displayed without being garbled.

class Test {
  static foo() {
    return "hi
  }
  static testMain() {
    List a = {1 : 1};
    List b = {1 : 1};
    return a == b;
  }
}

main() {
  TestNegativeTest.testMain();
}
