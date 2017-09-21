// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for testing class 'Strings'.

class StringsTest {
  StringsTest() {}

  toString() {
    return "Strings Tester";
  }

  static testCreation() {
    String s = "Hello";
    List<int> l = new List(s.length);
    for (int i = 0; i < l.length; i++) {
      l[i] = s.codeUnitAt(i);
    }
    String s2 = new String.fromCharCodes(l);
    Expect.equals(s, s2);
  }

  static void testMain() {
    testCreation();
  }
}

main() {
  StringsTest.testMain();
}
