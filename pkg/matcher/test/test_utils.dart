// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.test_utils;

import 'dart:async';

import 'package:matcher/matcher.dart';
import 'package:unittest/unittest.dart' show test, expectAsync;

int _errorCount;
String _errorString;
FailureHandler _testHandler = null;

class MyFailureHandler extends DefaultFailureHandler {
  void fail(String reason) {
    ++_errorCount;
    _errorString = reason;
  }
}

void initUtils() {
  if (_testHandler == null) {
    _testHandler = new MyFailureHandler();
  }
}

void shouldFail(value, Matcher matcher, expected, {bool isAsync: false}) {
  configureExpectFailureHandler(_testHandler);
  _errorCount = 0;
  _errorString = '';
  expect(value, matcher);
  afterTest() {
    configureExpectFailureHandler(null);
    expect(_errorCount, equals(1));
    if (expected is String) {
      expect(_errorString, equalsIgnoringWhitespace(expected));
    } else {
      expect(_errorString.replaceAll('\n', ''), expected);
    }
  }

  if (isAsync) {
    Timer.run(expectAsync(afterTest));
  } else {
    afterTest();
  }
}

void shouldPass(value, Matcher matcher, {bool isAsync: false}) {
  configureExpectFailureHandler(_testHandler);
  _errorCount = 0;
  _errorString = '';
  expect(value, matcher);
  afterTest() {
    configureExpectFailureHandler(null);
    expect(_errorCount, equals(0));
  }
  if (isAsync) {
    Timer.run(expectAsync(afterTest));
  } else {
    afterTest();
  }
}

doesNotThrow() {}
doesThrow() { throw 'X'; }

class PrefixMatcher extends Matcher {
  final String _prefix;
  const PrefixMatcher(this._prefix);
  bool matches(item, Map matchState) {
    return item is String &&
        (collapseWhitespace(item)).startsWith(collapseWhitespace(_prefix));
  }

  Description describe(Description description) =>
    description.add('a string starting with ').
        addDescriptionOf(collapseWhitespace(_prefix)).
        add(' ignoring whitespace');
}
