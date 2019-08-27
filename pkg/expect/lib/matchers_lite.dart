// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library is supposed help to remove dependencies on package:test from
/// an existing test.
///
/// Feel free to add more matchers, as long as they remain lite. Batteries
/// aren't included here. This is intended to be used in low-level platform
/// tests and shouldn't rely on advanced features such as reflection. Using
/// asynchronous code is acceptable, but only for testing code that is
/// *already* asynchronous, but try to avoid using "async" and other generators
/// (it's hard testing the implemention of generators if the test
/// infrastructure relies on them itself).
library expect.matchers_lite;

import "expect.dart" show Expect;

typedef Matcher = void Function(Object actual);

void expect(Object actual, Object expected) {
  if (expected is Matcher) {
    expected(actual);
  } else {
    equals(expected)(actual);
  }
}

Matcher unorderedEquals(Iterable<Object> expected) {
  return (Object actual) => Expect.setEquals(expected, actual);
}

fail(String message) {
  Expect.fail(message);
}

Matcher same(Object expected) {
  return (Object actual) => Expect.identical(expected, actual);
}

Matcher equals(Object expected) {
  if (expected is String) {
    return (Object actual) => Expect.stringEquals(expected, actual);
  } else if (expected is Iterable<Object>) {
    return (dynamic actual) =>
        Expect.listEquals(expected.toList(), actual.toList());
  } else {
    return (Object actual) => Expect.equals(expected, actual);
  }
}

final Matcher isEmpty = (dynamic actual) => Expect.isTrue(actual.isEmpty);

final Matcher isNull = (Object actual) => Expect.isNull(actual);
