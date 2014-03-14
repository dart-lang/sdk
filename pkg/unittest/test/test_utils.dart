// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_utils;

import 'package:unittest/unittest.dart';

import 'dart:async';

int errorCount;
String errorString;
var _testHandler = null;

class MyFailureHandler extends DefaultFailureHandler {
  void fail(String reason) {
    ++errorCount;
    errorString = reason;
  }
}

void initUtils() {
  if (_testHandler == null) {
    _testHandler = new MyFailureHandler();
  }
}

void shouldFail(value, Matcher matcher, expected, {bool isAsync: false}) {
  configureExpectFailureHandler(_testHandler);
  errorCount = 0;
  errorString = '';
  expect(value, matcher);
  afterTest() {
    configureExpectFailureHandler(null);
    expect(errorCount, equals(1));
    if (expected is String) {
      expect(errorString, equalsIgnoringWhitespace(expected));
    } else {
      expect(errorString.replaceAll('\n', ''), expected);
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
  errorCount = 0;
  errorString = '';
  expect(value, matcher);
  afterTest() {
    configureExpectFailureHandler(null);
    expect(errorCount, equals(0));
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
