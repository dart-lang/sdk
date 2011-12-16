// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test library for running tests inside the DARTest In-App test
 * runner along side the application under test in a browser.
 */
#library("unittest");

#import("dart:dom");

#source("shared.dart");

/** Getter so that the DARTest UI can access tests. */
List<TestCase> get tests() => _tests;

int testsRun = 0;
int testsFailed = 0;
int testsErrors = 0;

bool previousAsyncTest = false;

Function updateUI = null;

Function dartestLogger = null;

_platformDefer(void callback()) {
  _testRunner = runDartests;
  // DARTest ignores the callback. Tests are launched from UI.
}

// Update test results
updateTestStats(TestCase test) {
  assert(test.result != null);
  if(test.startTime != null) {
    test.runningTime = (new Date.now()).difference(test.startTime);
  }
  testsRun++;
  switch (test.result) {
    case 'fail': testsFailed++; break;
    case 'error': testsErrors++; break;   
  } 
  updateUI(test);
}

// Run tests sequentially
runDartests() {
  if(previousAsyncTest) {
    updateTestStats(_tests[_currentTest - 1]);
    previousAsyncTest = false;
  }
  if(_currentTest < _tests.length) {
    final testCase = _tests[_currentTest];
    dartestLogger('Running test:' + testCase.description);
    testCase.startTime = new Date.now();
    _runTest(testCase);
    if (!testCase.isComplete && testCase.callbacks > 0) {
      previousAsyncTest = true;
      return;
    }
    updateTestStats(testCase);
    _currentTest++;
    window.setTimeout(runDartests, 0);
  }
}

_platformStartTests() {
  // TODO(shauvik): Support for VM and command line coming soon!
  window.console.log("Warning: Running DARTest from VM or Command-line.");
}

_platformInitialize() {
  // Do nothing
}

_platformCompleteTests(int testsPassed, int testsFailed, int testsErrors) {
  // Do nothing
}

String getTestResultsCsv() {
  StringBuffer out = new StringBuffer();
  _tests.forEach((final test) {
    String result = 'none';
    if(test.result != null) {
      result = test.result.toUpperCase();
    }
    out.add('${test.id}, "${test.description}", $result\n');
  });
  return out.toString();
}