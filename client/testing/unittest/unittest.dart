// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test library for running tests in a browser.
 */
#library("unittest");

#import("dart:dom");

#source("shared.dart");

// TODO(rnystrom): Get rid of this if we get canonical closures for methods.
EventListener _onErrorClosure;

_platformInitialize() {
  _onErrorClosure = (e) { _onError(e); };
}

_platformDefer(void callback()) {
  window.setTimeout(callback, 0);
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
      _nextBatch();
    }
  }
}

/** Runs all queued tests, one at a time. */
_platformStartTests() {
  window.postMessage('unittest-suite-wait-for-done', '*');

  // Listen for uncaught errors.
  window.addEventListener('error', _onErrorClosure, true);
}

_platformCompleteTests(int testsPassed, int testsFailed, int testsErrors) {
  window.removeEventListener('error', _onErrorClosure);

  if (_isLayoutTest && testsPassed == _tests.length) {
    document.body.innerHTML = "PASS";
  } else {
    var newBody = new StringBuffer();
    newBody.add("<table class='unittest-table'><tbody>");
    newBody.add(testsPassed == _tests.length
        ? "<tr><td colspan='3' class='unittest-pass'>PASS</td></tr>"
        : "<tr><td colspan='3' class='unittest-fail'>FAIL</td></tr>");

    for (final test in _tests) {
      newBody.add(_toHtml(test));
    }

    if (testsPassed == _tests.length) {
      newBody.add("<tr><td colspan='3' class='unittest-pass'>All "
          + testsPassed + " tests passed</td></tr>");
    } else {
      newBody.add("""
          <tr><td colspan='3'>Total
            <span class='unittest-pass'>${testsPassed} passed</span>,
            <span class='unittest-fail'>${testsFailed} failed</span>
            <span class='unittest-error'>${testsErrors} errors</span>
          </td></tr>""");
    }
    newBody.add("</tbody></table>");
    document.body.innerHTML = newBody.toString();
  }

  window.postMessage('unittest-suite-done', '*');
}

String _toHtml(TestCase test) {
  if (!test.isComplete) {
    return '''
        <tr>
          <td>${test.id}</td>
          <td class="unittest-error">NO STATUS</td>
          <td>Test did not complete</td>
        </tr>''';
  }

  var html = '''
      <tr>
        <td>${test.id}</td>
        <td class="unittest-${test.result}">${test.result.toUpperCase()}</td>
        <td>Expectation: ${test.description}. ${test.message}</td>
      </tr>''';

  if (test.stackTrace != null) {
    html +=
        '<tr><td></td><td colspan="2"><pre>${test.stackTrace}</pre></td></tr>';
  }

  return html;
}
