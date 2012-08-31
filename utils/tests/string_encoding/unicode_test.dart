#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("unicode_tests");
#import("dunit.dart");
#import("../../../lib/utf/utf.dart");

void main() {
  TestSuite suite = new TestSuite();
  suite.registerTestClass(new UnicodeTests());
  suite.run();
}

class UnicodeTests extends TestClass {
  static const String testPhrase =
      "The quick brown fox jumps over the lazy dog.";

  static const List<int> testCodepoints = const<int> [
      84, 104, 101, 32, 113, 117, 105, 99, 107, 32, 98, 114, 111, 119, 110,
      32, 102, 111, 120, 32, 106, 117, 109, 112, 115, 32, 111, 118, 101, 114,
      32, 116, 104, 101, 32, 108, 97, 122, 121, 32, 100, 111, 103, 46];

  void registerTests(TestSuite suite) {
    register("testCodepointsToString", testCodepointsToString, suite);
    register("testStringToCodepoints", testStringToCodepoints, suite);
    register("testEmptyCodepointsToString", testEmptyCodepointsToString, suite);
    register("testEmptyStringToCodepoints", testEmptyStringToCodepoints, suite);
  }

  void testStringToCodepoints() {
    Expect.listEquals(testCodepoints, stringToCodepoints(testPhrase));
  }

  void testCodepointsToString() {
    Expect.stringEquals(testPhrase, codepointsToString(testCodepoints));
  }

  void testEmptyCodepointsToString() {
    Expect.stringEquals("", codepointsToString(<int>[]));
  }

  void testEmptyStringToCodepoints() {
    Expect.listEquals([], stringToCodepoints(""));
  }
}
