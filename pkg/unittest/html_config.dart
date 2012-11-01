// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test library for running tests in a browser.
 */
#library('unittest_html_config');

#import('dart:html');
#import('unittest.dart');

#source('html_print.dart');

class HtmlConfiguration extends Configuration {
  /** Whether this is run within dartium layout tests. */
  final bool _isLayoutTest;
  HtmlConfiguration(this._isLayoutTest);

  // TODO(rnystrom): Get rid of this if we get canonical closures for methods.
  EventListener _onErrorClosure;
  EventListener _onMessageClosure;

  void _installHandlers() {
    if (_onErrorClosure == null) {
      _onErrorClosure =
          (e) => handleExternalError(e, '(DOM callback has errors)');
      // Listen for uncaught errors.
      window.on.error.add(_onErrorClosure);
    }
    if (_onMessageClosure == null) {
      _onMessageClosure = (e) => processMessage(e);
      // Listen for errors from JS.
      window.on.message.add(_onMessageClosure);
    }
  }

  void _uninstallHandlers() {
    if (_onErrorClosure != null) {
      window.on.error.remove(_onErrorClosure);
      _onErrorClosure = null;
    }
    if (_onMessageClosure != null) {
      window.on.message.remove(_onMessageClosure);
      _onMessageClosure = null;
    }
  }

  void processMessage(e) {
    if ('unittest-suite-external-error' == e.data) {
      handleExternalError('<unknown>', '(external error detected)');
    }
  }

  void onInit() {
    _installHandlers();
  }

  void onStart() {
    window.postMessage('unittest-suite-wait-for-done', '*');
  }

  void onTestResult(TestCase testCase) {}

  void onDone(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    _uninstallHandlers();
    _showResultsInPage(passed, failed, errors, results, _isLayoutTest,
        uncaughtError);
    window.postMessage('unittest-suite-done', '*');
  }
}

void useHtmlConfiguration([bool isLayoutTest = false]) {
  configure(new HtmlConfiguration(isLayoutTest));
}
