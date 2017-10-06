// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing that NoSuchMethodError stops the program.

class NoSuchMethodNegativeTest {
  NoSuchMethodNegativeTest() {}

  foo() {
    return 1;
  }

  static testMain() {
    var obj = new NoSuchMethodNegativeTest();
    return obj.moo(); // NoSuchMethodError thrown here
  }
}

main() {
  NoSuchMethodNegativeTest.testMain();
}
