// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): replace this with the real package:test.
// Not possible yet due to various bugs we still have.
library minitest;

import 'dart:async';
import 'package:dom/dom.dart';

void group(String name, void body()) => (window as dynamic).suite(name, body);

void test(String name, body(), {String skip}) {
  if (skip != null) {
    print('SKIP $name: $skip');
    return;
  }
  (window as dynamic).test(name, (done) {
    _finishTest(f) {
      if (f is Future) {
        f.then(_finishTest);
      } else {
        done();
      }
    }
    _finishTest(body());
  });
}

void expect(Object actual, matcher) {
  if (matcher is! Matcher) matcher = equals(matcher);
  if (!matcher(actual)) {
    throw 'Expect failed to match $actual with $matcher';
  }
}

void fail(String message) {
  throw 'TestFailure: ' + message;
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

bool isTrue(actual) => actual == true;
bool isNull(actual) => actual == null;
final Matcher isNotNull = isNot(isNull);
bool isRangeError(actual) => actual is RangeError;
bool isNoSuchMethodError(actual) => actual is NoSuchMethodError;
Matcher lessThan(expected) => (actual) => actual < expected;
Matcher greaterThan(expected) => (actual) => actual > expected;

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
