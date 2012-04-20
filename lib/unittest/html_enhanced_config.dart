// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test library for running tests in a browser.
 *
 * Provides enhanced HTML output with collapsible group headers
 * and other at-a-glance information about the test results.
 */
#library('unittest');

#import('dart:html');
#import('unittest.dart');


class HtmlEnhancedConfiguration extends Configuration {
  /** Whether this is run within dartium layout tests. */
  final bool _isLayoutTest;
  HtmlEnhancedConfiguration(this._isLayoutTest);

  // TODO(rnystrom): Get rid of this if we get canonical closures for methods.
  EventListener _onErrorClosure;

  void onInit() {
    //initialize and load CSS
    final String _CSSID = '_unittestcss_';

    var cssElement = document.head.query('#${_CSSID}');
    if (cssElement == null){
      document.head.elements.add(new Element.html(
          '<style id="${_CSSID}"></style>'));
      cssElement = document.head.query('#${_CSSID}');
    }

    cssElement.innerHTML = _htmlTestCSS;

    _onErrorClosure = (e) {
      // TODO(vsm): figure out how to expose the stack trace here
      // Currently e.message works in dartium, but not in dartc.
      notifyError('(DOM callback has errors) Caught ${e}', '');
    };
  }

  void onStart() {
    window.postMessage('unittest-suite-wait-for-done', '*');
    // Listen for uncaught errors.
    window.on.error.add(_onErrorClosure);
  }

  void onTestResult(TestCase testCase) {}

  void onDone(int passed, int failed, int errors, List<TestCase> results) {
    window.on.error.remove(_onErrorClosure);

    _showInteractiveResultsInPage(passed, failed, errors, results,
        _isLayoutTest);

    window.postMessage('unittest-suite-done', '*');
  }

  void _showInteractiveResultsInPage(int passed, int failed, int errors,
      List<TestCase> results, bool isLayoutTest){
    if (isLayoutTest && passed == results.length) {
      document.body.innerHTML = "PASS";
    } else {
      // changed the StringBuffer to an Element fragment
      Element te = new Element.html('<div class="unittest-table"></div>');

      te.elements.add(new Element.html(passed == results.length
          ? "<div class='unittest-overall unittest-pass'>PASS</div>"
          : "<div class='unittest-overall unittest-fail'>FAIL</div>"));

      // moved summary to the top since web browsers
      // don't auto-scroll to the bottom like consoles typically do.
      if (passed == results.length) {
        te.elements.add(new Element.html("""
          <div class='unittest-pass'>All ${passed} tests passed</div>"""));
      } else {

        te.elements.add(new Element.html("""
        <div class='unittest-summary'>
          <span class='unittest-pass'>Total ${passed} passed</span>,
          <span class='unittest-fail'>${failed} failed</span>,
          <span class='unittest-error'>${errors} errors</span>
        </div>"""));
      }

      te.elements.add(new Element.html("""
        <div><button id='btnCollapseAll'>Collapse All</button></div>
       """));

      // handle the click event for the collapse all button
      te.query('#btnCollapseAll').on.click.add((_){
        document
          .queryAll('.unittest-row')
          .forEach((el) => el.attributes['class'] = el.attributes['class']
              .replaceAll('unittest-row ', 'unittest-row-hidden '));
      });

      var previousGroup = '';
      var groupPassFail = true;
      final indentAmount = 50;

      // order by group and sort numerically within each group
      var groupedBy = new LinkedHashMap<String, List<TestCase>>();

      for (final t in results){
        if (!groupedBy.containsKey(t.currentGroup)){
          groupedBy[t.currentGroup] = new List<TestCase>();
        }

        groupedBy[t.currentGroup].add(t);
      }

      // flatten the list again with tests ordered
      List<TestCase> flattened = new List<TestCase>();

      groupedBy
        .getValues()
        .forEach((tList){
          tList.sort((tcA, tcB) => tcA.id - tcB.id);
          flattened.addAll(tList);
          }
        );

      // output group headers and test rows
      for (final test_ in flattened) {

        // replace everything but numbers and letters from the group name with
        // '_' so we can use in id and class properties.
        var safeGroup = test_.currentGroup
                              .replaceAll("(?:[^a-z0-9 ]|(?<=['\"])s)",'_')
                              .replaceAll(' ','_');

        if (test_.currentGroup != previousGroup){

          previousGroup = test_.currentGroup;

          var testsInGroup = results.filter(
              (TestCase t) => t.currentGroup == previousGroup);
          var groupTotalTestCount = testsInGroup.length;
          var groupTestPassedCount = testsInGroup.filter(
              (TestCase t) => t.result == 'pass').length;
          groupPassFail = groupTotalTestCount == groupTestPassedCount;

          te.elements.add(new Element.html("""
            <div>
              <div id='${safeGroup}'
                   class='unittest-group ${safeGroup} test${safeGroup}'>
                <div ${_isIE ? "style='display:inline-block' ": ""}
                     class='unittest-row-status'>
                  <div class='unittest-group-status unittest-group-status-
                              ${groupPassFail ? 'pass' : 'fail'}'></div>
                </div>
                <div ${_isIE ? "style='display:inline-block' ": ""}>
                    ${test_.currentGroup}</div>
                <div ${_isIE ? "style='display:inline-block' ": ""}>
                    (${groupTestPassedCount}/${groupTotalTestCount})</div>
              </div>
            </div>"""));

          var grp = te.query('#${safeGroup}');
          if (grp != null){
            grp.on.click.add((_){
              var row = document.query('.unittest-row-${safeGroup}');
              if (row.attributes['class'].contains('unittest-row ')){
                document.queryAll('.unittest-row-${safeGroup}').forEach(
                    (e) => e.attributes['class'] =  e.attributes['class']
                        .replaceAll('unittest-row ', 'unittest-row-hidden '));
              }else{
                document.queryAll('.unittest-row-${safeGroup}').forEach(
                    (e) => e.attributes['class'] = e.attributes['class']
                        .replaceAll('unittest-row-hidden', 'unittest-row'));
              }
            });
          }
        }

        _buildRow(test_, te, safeGroup, !groupPassFail);
      }

      document.body.elements.clear();
      document.body.elements.add(te);
    }
  }

  void _buildRow(TestCase test_, Element te, String groupID, bool isVisible) {
    var background = 'unittest-row-${test_.id % 2 == 0 ? "even" : "odd"}';
    var display = '${isVisible ? "unittest-row" : "unittest-row-hidden"}';

    // TODO (prujohn@gmail.com) I had to borrow this from html_print.dart
    // Probably should put it in some more common location.
    String _htmlEscape(String string) {
      return string.replaceAll('&', '&amp;')
                   .replaceAll('<','&lt;')
                   .replaceAll('>','&gt;');
    }

    addRowElement(id, status, description){
      te.elements.add(
        new Element.html(
          ''' <div>
                <div class='$display unittest-row-${groupID} $background'>
                  <div ${_isIE ? "style='display:inline-block' ": ""}
                       class='unittest-row-id'>$id</div>
                  <div ${_isIE ? "style='display:inline-block' ": ""}
                       class="unittest-row-status unittest-${test_.result}">
                       $status</div>
                  <div ${_isIE ? "style='display:inline-block' ": ""}
                       class='unittest-row-description'>$description</div>
                </div>
              </div>'''
        )
      );
    }

    if (!test_.isComplete) {
       addRowElement('${test_.id}', 'NO STATUS', 'Test did not complete.');
       return;
    }

    addRowElement('${test_.id}', '${test_.result.toUpperCase()}',
        '${test_.description}. ${_htmlEscape(test_.message)}');

    if (test_.stackTrace != null) {
      addRowElement('', '', '<pre>${_htmlEscape(test_.stackTrace)}</pre>');
    }
  }


  static bool get _isIE() => document.window.navigator.userAgent.contains('MSIE');

  String get _htmlTestCSS() =>
  '''
  body{
    font-size: 14px;
    font-family: 'Open Sans', 'Lucida Sans Unicode', 'Lucida Grande', sans-serif;
    background: WhiteSmoke;
  }

  .unittest-group
  {
    background: rgb(75,75,75);
    width:98%;
    color: WhiteSmoke;
    font-weight: bold;
    padding: 6px;

    /* Provide some visual separation between groups for IE */
    ${_isIE ? "border-bottom:solid black 1px;": ""}
    ${_isIE ? "border-top:solid #777777 1px;": ""}

    background-image: -webkit-linear-gradient(bottom, rgb(50,50,50) 0%, rgb(100,100,100) 100%);
    background-image: -moz-linear-gradient(bottom, rgb(50,50,50) 0%, rgb(100,100,100) 100%);
    background-image: -ms-linear-gradient(bottom, rgb(50,50,50) 0%, rgb(100,100,100) 100%);
    background-image: linear-gradient(bottom, rgb(50,50,50) 0%, rgb(100,100,100) 100%);

    display: -webkit-box;
    display: -moz-box;
    display: -ms-box;
    display: box;

    -webkit-box-orient: horizontal;
    -moz-box-orient: horizontal;
    -ms-box-orient: horizontal;
    box-orient: horizontal;

    -webkit-box-align: center;
    -moz-box-align: center;
    -ms-box-align: center;
    box-align: center;
   }

  .unittest-group-status
  {
    width: 20px;
    height: 20px;
    border-radius: 20px;
    margin-left: 10px;
  }

  .unittest-group-status-pass{
    background: Green;
    background: -webkit-radial-gradient(center, ellipse cover, #AAFFAA 0%,Green 100%);
    background: -moz-radial-gradient(center, ellipse cover, #AAFFAA 0%,Green 100%);
    background: -ms-radial-gradient(center, ellipse cover, #AAFFAA 0%,Green 100%);
    background: radial-gradient(center, ellipse cover, #AAFFAA 0%,Green 100%);
  }

  .unittest-group-status-fail{
    background: Red;
    background: -webkit-radial-gradient(center, ellipse cover, #FFAAAA 0%,Red 100%);
    background: -moz-radial-gradient(center, ellipse cover, #FFAAAA 0%,Red 100%);
    background: -ms-radial-gradient(center, ellipse cover, #AAFFAA 0%,Green 100%);
    background: radial-gradient(center, ellipse cover, #FFAAAA 0%,Red 100%);
  }

  .unittest-overall{
    font-size: 20px;
  }

  .unittest-summary{
    font-size: 18px;
  }

  .unittest-pass{
    color: Green;
  }

  .unittest-fail, .unittest-error
  {
    color: Red;
  }

  .unittest-row
  {
    display: -webkit-box;
    display: -moz-box;
    display: -ms-box;
    display: box;
    -webkit-box-orient: horizontal;
    -moz-box-orient: horizontal;
    -ms-box-orient: horizontal;
    box-orient: horizontal;
    width: 100%;
  }

  .unittest-row-hidden
  {
    display: none;
  }

  .unittest-row-odd
  {
    background: WhiteSmoke;
  }

  .unittest-row-even
  {
    background: #E5E5E5;
  }

  .unittest-row-id
  {
    width: 3em;
  }

  .unittest-row-status
  {
    width: 4em;
  }

  .unittest-row-description
  {
  }

  ''';
}

void useHtmlEnhancedConfiguration([bool isLayoutTest = false]) {
  configure(new HtmlEnhancedConfiguration(isLayoutTest));
}
