// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Utility functions to easy porting of V8 tests.

import "package:expect/expect.dart";

void assertEquals(actual, expected, [message]) {
  Expect.equals(actual, expected, message);
}
void assertTrue(actual, [message]) { Expect.isTrue(actual, message); }
void assertFalse(actual, [message]) { Expect.isFalse(actual, message); }
void assertThrows(fn, [testid]) { Expect.throws(fn, null, testid); }
void assertNull(actual, [testid]) { Expect.isNull(actual, testid); }

void assertToStringEquals(str, match, testid) {
  var actual = [];
  for (int i = 0; i <= match.groupCount; i++) {
    actual.add(match.group(i));
  }

  Expect.equals(str,
                actual.map((s) => (s == null) ? "" : s).join(","),
                "Test $testid failed");
}

void shouldBeTrue(actual) { Expect.isTrue(actual); }
void shouldBeFalse(actual) { Expect.isFalse(actual); }
void shouldBeNull(actual) { Expect.isNull(actual); }

void shouldBe(actual, expected, [message]) {
  if (expected == null) {
    Expect.isNull(actual);
  } else {
    Expect.equals(expected.length, actual.groupCount + 1);
    for (int i = 0; i <= actual.groupCount; i++) {
      Expect.equals(expected[i], actual.group(i));
    }
  }
}

Match firstMatch(String str, RegExp pattern) => pattern.firstMatch(str);
List<String> allStringMatches(String str, RegExp pattern) =>
    pattern.allMatches(str).map((Match m) => m.group(0)).toList();

void description(str) { }
