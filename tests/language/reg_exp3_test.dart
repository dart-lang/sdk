// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

class RegExp3Test {
  static testMain() {
    var i = 2000;
    try {
      RegExp exp = new RegExp("[");
      i = 100;  // Should not reach here.
    } catch (IllegalJSRegExpException e) {
      i = 0;
    }
    Expect.equals(0, i);
  }
}

main() {
  RegExp3Test.testMain();
}
