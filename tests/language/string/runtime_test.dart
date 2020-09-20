// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Replace with shared test once interface issues clarified.

import "package:expect/expect.dart";

class StringTest {
  static testMain() {
    testCodePoints();
    testNoSuchMethod();
    testStringsJoin();
    testCharCodes();
  }

  static testCodePoints() {
    String str = "string";
    for (int i = 0; i < str.length; i++) {
      Expect.equals(true, str[i] is String);
      Expect.equals(true, str.codeUnitAt(i) is int);
    }
  }

  static testStringsJoin() {
    List<String> a = ["Hello", "World"];
    String s = a.join("*^*");
    Expect.equals("Hello*^*World", s);
  }

  static testNoSuchMethod() {
    String a = "Hello";

  }

  static testCharCodes() {
    String s = new String.fromCharCodes(const [0x41, 0xC1, 0x424]);
    Expect.equals("A", s[0]);
    Expect.equals(0x424, s.codeUnitAt(2));
  }
}

main() {
  StringTest.testMain();
}
