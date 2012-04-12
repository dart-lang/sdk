// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test library for running tests in a browser.
 */
#library('unittest');

#import('dart:dom');
#import('dart:isolate');

#source('config.dart');
#source('shared.dart');
#source('html_print.dart');

/** Whether this is run within dartium layout tests. */
bool _isLayoutTest = false;

void forLayoutTests() {
  _isLayoutTest = true;
}

class PlatformConfiguration extends Configuration {
  // TODO(rnystrom): Get rid of this if we get canonical closures for methods.
  EventListener _onErrorClosure;

  void onInit() {
    _onErrorClosure = (e) { _onError(e); };
  }

  void _onError(e) {
   if (_currentTest < _tests.length) {
      final testCase = _tests[_currentTest];
      // TODO(vsm): figure out how to expose the stack trace here
      // Currently e.message works in dartium, but not in dartc.
      testCase.error('(DOM callback has errors) Caught ${e}', '');
      _state = _UNCAUGHT_ERROR;
      if (testCase.callbacks > 0) {
        _currentTest++;
        _testRunner();
      }
    }
  }

  void onStart() {
    window.postMessage('unittest-suite-wait-for-done', '*');
    // Listen for uncaught errors.
    window.addEventListener('error', _onErrorClosure, true);
  }

  void onTestResult(TestCase testCase) {}

  void onDone(int passed, int failed, int errors, List<TestCase> results) {
    window.removeEventListener('error', _onErrorClosure);
    _showResultsInPage(passed, failed, errors, results, _isLayoutTest);
    window.postMessage('unittest-suite-done', '*');
  }
}
