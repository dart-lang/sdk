// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): replace this with the real package:test.
// Not possible yet because it uses on async/await which we don't support.
library minitest;

import 'dom.dart';

final console = (window as dynamic).console;

void group(String name, void body()) {
  console.group(name);
  body();
  console.groupEnd(name);
}

void test(String name, void body(), {String skip}) {
  if (skip != null) {
    console.warn('SKIP $name: $skip');
    return;
  }
  console.log(name);
  try {
    body();
  } catch(e) {
    console.error(e);
  }
}

void expect(Object actual, matcher) {
  if (matcher is! Matcher) matcher = equals(matcher);
  if (!matcher(actual)) {
    throw 'Expect failed to match $actual with $matcher';
  }
}

Matcher equals(Object expected) {
  return (actual) {
    if (expected is List && actual is List) {
      int len = expected.length;
      if (len != actual.length) return false;
      for (int i = 0; i < len; i++) {
        if (!equals(expected[i])(actual[i])) return false;
      }
      return true;
    } else {
      return expected == actual;
    }
  };
}

Matcher same(Object expected) => (actual) => identical(expected, actual);
Matcher isNot(matcher) {
  if (matcher is! Matcher) matcher = equals(matcher);
  return (actual) => !matcher(actual);
}

bool isNull(actual) => actual == null;
final Matcher isNotNull = isNot(isNull);
bool isRangeError(actual) => actual is RangeError;
bool isNoSuchMethodError(actual) => actual is NoSuchMethodError;

Matcher throwsA(matcher) {
  if (matcher is! Matcher) matcher = equals(matcher);
  return (actual) {
    try {
      actual();
      return false;
    } catch(e) {
      return matcher(e);
    }
  };
}

final Matcher throws = throwsA((a) => true);

typedef Matcher(actual);
