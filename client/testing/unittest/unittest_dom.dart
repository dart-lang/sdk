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
      _testRunner();
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

    for (final test_ in _tests) {
      newBody.add(_toHtml(test_));
    }

    if (testsPassed == _tests.length) {
      newBody.add("""
          <tr><td colspan='3' class='unittest-pass'>
            All ${testsPassed} tests passed
          </td></tr>""");
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

String _toHtml(TestCase test_) {
  if (!test_.isComplete) {
    return '''
        <tr>
          <td>${test_.id}</td>
          <td class="unittest-error">NO STATUS</td>
          <td>Test did not complete</td>
        </tr>''';
  }

  var html = '''
      <tr>
        <td>${test_.id}</td>
        <td class="unittest-${test_.result}">${test_.result.toUpperCase()}</td>
        <td>Expectation: ${test_.description}. ${_htmlEscape(test_.message)}</td>
      </tr>''';

  if (test_.stackTrace != null) {
    html +=
        '<tr><td></td><td colspan="2"><pre>${_htmlEscape(test_.stackTrace)}</pre></td></tr>';
  }

  return html;
}

//TODO(pquitslund): Move to a common lib
String _htmlEscape(String string) {
  return string.replaceAll('&', '&amp;')
               .replaceAll('<','&lt;')
               .replaceAll('>','&gt;');
}