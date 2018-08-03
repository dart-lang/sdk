// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Utility functions to easily port V8 tests.

import "package:expect/expect.dart";

void assertEquals(actual, expected, [String message = null]) {
  Expect.equals(actual, expected, message);
}

void assertTrue(actual, [String message = null]) {
  Expect.isTrue(actual, message);
}

void assertFalse(actual, [String message = null]) {
  Expect.isFalse(actual, message);
}

void assertThrows(fn, [num testid = null]) {
  Expect.throws(fn, null, "Test $testid");
}

void assertNull(actual, [num testid = null]) {
  Expect.isNull(actual, "Test $testid");
}

void assertToStringEquals(str, match, num testid) {
  var actual = [];
  for (int i = 0; i <= match.groupCount; i++) {
    var g = match.group(i);
    actual.add((g == null) ? "" : g);
  }
  Expect.equals(str, actual.join(","), "Test $testid");
}

void shouldBeTrue(actual) {
  Expect.isTrue(actual);
}

void shouldBeFalse(actual) {
  Expect.isFalse(actual);
}

void shouldBeNull(actual) {
  Expect.isNull(actual);
}

void shouldBe(actual, expected, [String message = null]) {
  if (expected == null) {
    Expect.isNull(actual, message);
  } else {
    Expect.equals(expected.length, actual.groupCount + 1);
    for (int i = 0; i <= actual.groupCount; i++) {
      Expect.equals(expected[i], actual.group(i), message);
    }
  }
}

Match firstMatch(String str, RegExp pattern) => pattern.firstMatch(str);
List<String> allStringMatches(String str, RegExp pattern) =>
    pattern.allMatches(str).map((Match m) => m.group(0)).toList();

void description(str) {}
