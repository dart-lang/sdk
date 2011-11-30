// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing class 'StringBase' (currently VM specific).

#library("StringBaseTest.dart");
#import("dart:coreimpl");


class StringBaseTest {

  StringBaseTest() {}

  toString() {
    return "StringBase Tester";
  }
  static testSubstringMatches() {
    Expect.equals(true, "Hello".substringMatches(0, "Hello"));
    Expect.equals(true, "Hello World".substringMatches(0, "Hello"));
    Expect.equals(false, "My Hello World".substringMatches(0, "Hello"));
    Expect.equals(true, "My Hello World".substringMatches(6, "lo W"));
    Expect.equals(false, "Hello".substringMatches(0, "low"));
  }

  static testInterpolation() {
    var answer = 40 + 2;
    var s = "The answer is $answer.";
    Expect.equals("The answer is 42.", s);

    int numBottles = 33;
    String wall = "wall";
    s = "${numBottles*3} bottles of beer on the $wall.";
    Expect.equals("99 bottles of beer on the wall.", s);
  }

  static testCreation() {
    String s = "Hello";
    List<int> a = new List(s.length);
    List<int> ga  = new List();
    bool exception_caught = false;
    for (int i = 0; i < a.length; i++) {
      a[i] = s.charCodeAt(i);
      ga.add(s.charCodeAt(i));
    }
    String s2 = StringBase.createFromCharCodes(a);
    Expect.equals(s, s2);
    String s3 = StringBase.createFromCharCodes(ga);
    Expect.equals(s, s3);
    try {
      String s4 = new String.fromCharCodes([0.0]);
    } catch (IllegalArgumentException ex) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
    exception_caught = false;
    try {
      String s4 = new String.fromCharCodes([-1]);
    } catch (IllegalArgumentException ex) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
  }

  static testSubstring() {
    String s = "Hello World";
    Expect.equals("World", s.substring(6, s.length));
    Expect.equals("", s.substring(8, 8));
    bool exception_caught = false;
    try {
      s.substring(5, 12);
    } catch (IndexOutOfRangeException ex) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
    exception_caught = false;
    try {
      s.substring(5, 4);
    } catch (IndexOutOfRangeException ex) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
  }

  static void testMain() {
    testSubstringMatches();
    testInterpolation();
    testCreation();
    testSubstring();
  }
}

main() {
  StringBaseTest.testMain();
}
