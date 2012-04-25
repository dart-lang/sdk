// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Configuration for running tests in a browser using dart:dom. */
#library('dom_config');

#import('dart:dom');
#import('unittest.dart');

#source('html_print.dart');

class DomConfiguration extends Configuration {
  /** Whether this is run within dartium layout tests. */
  final bool _isLayoutTest;

  DomConfiguration(this._isLayoutTest);

  // TODO(rnystrom): Get rid of this if we get canonical closures for methods.
  EventListener _onErrorClosure;

  void onInit() {
    _onErrorClosure = (e) {
      // TODO(vsm): figure out how to expose the stack trace here
      // Currently e.message works in dartium, but not in dartc.
      notifyError('(DOM callback has errors) Caught $e', '');
    };
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

void useDomConfiguration([bool isLayoutTest = false]) {
  configure(new DomConfiguration(isLayoutTest));
}
