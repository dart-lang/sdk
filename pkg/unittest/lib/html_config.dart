// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test library for running tests in a browser.
 */
library unittest_html_config;

import 'dart:async';
import 'dart:html';
import 'unittest.dart';

/** Creates a table showing tests results in HTML. */
void _showResultsInPage(int passed, int failed, int errors,
    List<TestCase> results, bool isLayoutTest, String uncaughtError) {
  if (isLayoutTest && (passed == results.length) && uncaughtError == null) {
    document.body.innerHtml = "PASS";
  } else {
    var newBody = new StringBuffer();
    newBody.write("<table class='unittest-table'><tbody>");
    newBody.write(passed == results.length && uncaughtError == null
        ? "<tr><td colspan='3' class='unittest-pass'>PASS</td></tr>"
        : "<tr><td colspan='3' class='unittest-fail'>FAIL</td></tr>");

    for (final test_ in results) {
      newBody.write(_toHtml(test_));
    }

    if (uncaughtError != null) {
        newBody.write('''<tr>
          <td>--</td>
          <td class="unittest-error">ERROR</td>
          <td>Uncaught error: $uncaughtError</td>
        </tr>''');
    }

    if (passed == results.length && uncaughtError == null) {
      newBody.write("""
          <tr><td colspan='3' class='unittest-pass'>
            All ${passed} tests passed
          </td></tr>""");
    } else {
      newBody.write("""
          <tr><td colspan='3'>Total
            <span class='unittest-pass'>${passed} passed</span>,
            <span class='unittest-fail'>${failed} failed</span>
            <span class='unittest-error'>
            ${errors + (uncaughtError == null ? 0 : 1)} errors</span>
          </td></tr>""");
    }
    newBody.write("</tbody></table>");
    document.body.innerHtml = newBody.toString();

    window.onHashChange.listen((_) {
      // Location may change from individual tests setting the hash tag.
      if (window.location.hash != null &&
          window.location.hash.contains('testFilter')) {
        window.location.reload();
      }
    });
  }
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
        <td>Expectation: <a href="#testFilter=${test_.description}">${test_.description}</a>. ${_htmlEscape(test_.message)}</td>
      </tr>''';

  if (test_.stackTrace != null) {
    html = '$html<tr><td></td><td colspan="2"><pre>${_htmlEscape(test_.stackTrace)}</pre></td></tr>';
  }

  return html;
}

//TODO(pquitslund): Move to a common lib
String _htmlEscape(String string) {
  return string.replaceAll('&', '&amp;')
               .replaceAll('<','&lt;')
               .replaceAll('>','&gt;');
}

class HtmlConfiguration extends Configuration {
  /** Whether this is run within dartium layout tests. */
  final bool _isLayoutTest;
  HtmlConfiguration(this._isLayoutTest);

  StreamSubscription<Event> _onErrorSubscription;
  StreamSubscription<Event> _onMessageSubscription;

  void _installHandlers() {
    if (_onErrorSubscription == null) {
      _onErrorSubscription = window.onError.listen(
        (e) => handleExternalError(e, '(DOM callback has errors)'));
    }
    if (_onMessageSubscription == null) {
      _onMessageSubscription = window.onMessage.listen(
        (e) => processMessage(e));
    }
  }

  void _uninstallHandlers() {
    if (_onErrorSubscription != null) {
      _onErrorSubscription.cancel();
      _onErrorSubscription = null;
    }
    if (_onMessageSubscription != null) {
      _onMessageSubscription.cancel();
      _onMessageSubscription = null;
    }
  }

  void processMessage(e) {
    if ('unittest-suite-external-error' == e.data) {
      handleExternalError('<unknown>', '(external error detected)');
    }
  }

  void onInit() {
    _installHandlers();
    window.postMessage('unittest-suite-wait-for-done', '*');
  }

  void onStart() {
    // If the URL has a #testFilter=testName then filter tests to that.
    // This is used to make it easy to run a single test- but is only intended
    // for interactive debugging scenarios.
    var hash = window.location.hash;
    if (hash != null && hash.length > 1) {
      var params = hash.substring(1).split('&');
      for (var param in params) {
        var parts = param.split('=');
        if (parts.length == 2 && parts[0] == 'testFilter') {
          filterTests('^${parts[1]}');
        }
      }
    }
    super.onStart();
  }

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    _showResultsInPage(passed, failed, errors, results, _isLayoutTest,
        uncaughtError);
  }

  void onDone(bool success) {
    _uninstallHandlers();
    window.postMessage('unittest-suite-done', '*');
  }
}

void useHtmlConfiguration([bool isLayoutTest = false]) {
  if (config != null) return;
  configure(new HtmlConfiguration(isLayoutTest));
}
