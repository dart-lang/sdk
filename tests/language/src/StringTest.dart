// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Replace with shared test once interface issues clarified.

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
      Expect.equals(true, str.charCodeAt(i) is int);
    }
  }

  static testStringsJoin() {
    List<String> a = new List<String>(2);
    a[0] = "Hello";
    a[1] = "World";
    String s = Strings.join(a, "*^*");
    Expect.equals("Hello*^*World", s);
  }

  static testNoSuchMethod() {
    String a = "Hello";
    bool exception_caught = false;
    try {
      a[1] = 12;  // Throw exception.
    } catch (NoSuchMethodException e) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
  }

  static testCharCodes() {
    String s = new String.fromCharCodes(const [0x41, 0xC1, 0x424]);
    Expect.equals("A", s[0]);
    Expect.equals(0x424, s.charCodeAt(2));
  }
}

main() {
  StringTest.testMain();
}
