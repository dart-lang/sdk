// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/** Creates a table showing tests results in HTML. */
void _showResultsInPage(int testsPassed, int testsFailed, int testsErrors,
    List<TestCase> results, isLayoutTest) {
  if (isLayoutTest && (testsPassed == results.length)) {
    document.body.innerHTML = "PASS";
  } else {
    var newBody = new StringBuffer();
    newBody.add("<table class='unittest-table'><tbody>");
    newBody.add(testsPassed == results.length
        ? "<tr><td colspan='3' class='unittest-pass'>PASS</td></tr>"
        : "<tr><td colspan='3' class='unittest-fail'>FAIL</td></tr>");

    for (final test_ in results) {
      newBody.add(_toHtml(test_));
    }

    if (testsPassed == results.length) {
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
