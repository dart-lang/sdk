// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of unittestTests;

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
     expect(errorString, expected);
    }
  }

  if (isAsync) {
    Timer.run(expectAsync0(afterTest));
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
    Timer.run(expectAsync0(afterTest));
  } else {
    afterTest();
  }
}
