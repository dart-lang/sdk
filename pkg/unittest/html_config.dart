// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test library for running tests in a browser.
 */
#library('unittest');

#import('dart:html');
#import('unittest.dart');

#source('html_print.dart');

class HtmlConfiguration extends Configuration {
  /** Whether this is run within dartium layout tests. */
  final bool _isLayoutTest;
  HtmlConfiguration(this._isLayoutTest);

  // TODO(rnystrom): Get rid of this if we get canonical closures for methods.
  EventListener _onErrorClosure;

  void _installErrorHandler() {
    if (_onErrorClosure == null) {
      _onErrorClosure =
          (e) => handleExternalError(e, '(DOM callback has errors)');
      // Listen for uncaught errors.
      window.on.error.add(_onErrorClosure);
    }
  }

  void _uninstallErrorHandler() {
    if (_onErrorClosure != null) {
      window.on.error.remove(_onErrorClosure);
      _onErrorClosure = null;
    }
  }

  void onInit() {
    _installErrorHandler();
  }

  void onStart() {
    window.postMessage('unittest-suite-wait-for-done', '*');
  }

  void onTestResult(TestCase testCase) {}

  void onDone(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    _uninstallErrorHandler();
    _showResultsInPage(passed, failed, errors, results, _isLayoutTest,
        uncaughtError);
    window.postMessage('unittest-suite-done', '*');
  }
}

void useHtmlConfiguration([bool isLayoutTest = false]) {
  configure(new HtmlConfiguration(isLayoutTest));
}
