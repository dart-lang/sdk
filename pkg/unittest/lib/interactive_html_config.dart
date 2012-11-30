// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This configuration can be used to rerun selected tests, as well
 * as see diagnostic output from tests. It runs each test in its own
 * IFrame, so the configuration consists of two parts - a 'parent'
 * config that manages all the tests, and a 'child' config for the
 * IFrame that runs the individual tests.
 */
library unittest_interactive_html_config;

// TODO(gram) - add options for: remove IFrame on done/keep
// IFrame for failed tests/keep IFrame for all tests.

import 'dart:html';
import 'dart:math';
import 'unittest.dart';

/** The messages exchanged between parent and child. */

class _Message {
  static const START = 'start';
  static const LOG = 'log';
  static const STACK = 'stack';
  static const PASS = 'pass';
  static const FAIL = 'fail';
  static const ERROR = 'error';

  String messageType;
  int elapsed;
  String body;

  static String text(String messageType,
                     [int elapsed = 0, String body = '']) =>
      '$messageType $elapsed $body';

  _Message(this.messageType, [this.elapsed = 0, this.body = '']);

  _Message.fromString(String msg) {
    int idx = msg.indexOf(' ');
    messageType = msg.substring(0, idx);
    ++idx;
    int idx2 = msg.indexOf(' ', idx);
    elapsed = int.parse(msg.substring(idx, idx2));
    ++idx2;
    body = msg.substring(idx2);
  }

  String toString() => text(messageType, elapsed, body);
}


class HtmlConfiguration extends Configuration {
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
}

/**
 * The child configuration that is used to run individual tests in
 * an IFrame and post the results back to the parent. In principle
 * this can run more than one test in the IFrame but currently only
 * one is used.
 */
class ChildInteractiveHtmlConfiguration extends HtmlConfiguration {

  /** The window to which results must be posted. */
  Window parentWindow;

  /** The time at which tests start. */
  Map<int,Date> _testStarts;

  ChildInteractiveHtmlConfiguration() :
      _testStarts = new Map<int,Date>();

  /** Don't start running tests automatically. */
  get autoStart => false;

  void onInit() {
    _installErrorHandler();

    /**
     *  The parent posts a 'start' message to kick things off,
     *  which is handled by this handler. It saves the parent
     *  window, gets the test ID from the query parameter in the
     *  IFrame URL, sets that as a solo test and starts test execution.
     */
    window.on.message.add((MessageEvent e) {
      // Get the result, do any logging, then do a pass/fail.
      var m = new _Message.fromString(e.data);
      if (m.messageType == _Message.START) {
        parentWindow = e.source;
        String search = window.location.search;
        int pos = search.indexOf('t=');
        String ids = search.substring(pos+2);
        int id = int.parse(ids);
        setSoloTest(id);
        runTests();
      }
    });
  }

  void onStart() {
    _installErrorHandler();
  }

  /** Record the start time of the test. */
  void onTestStart(TestCase testCase) {
    super.onTestStart(testCase);
    _testStarts[testCase.id]= new Date.now();
  }

  /**
   * Tests can call [logMessage] for diagnostic output. These log
   * messages in turn get passed to this method, which adds
   * a timestamp and posts them back to the parent window.
   */
  void logTestCaseMessage(TestCase testCase, String message) {
    int elapsed;
    if (testCase == null) {
      elapsed = -1;
    } else {
      Date end = new Date.now();
      elapsed = end.difference(_testStarts[testCase.id]).inMilliseconds;
    }
    parentWindow.postMessage(
      _Message.text(_Message.LOG, elapsed, message).toString(), '*');
  }

  /**
   * Get the elapsed time for the test, anbd post the test result
   * back to the parent window. If the test failed due to an exception
   * the stack is posted back too (before the test result).
   */
  void onTestResult(TestCase testCase) {
    super.onTestResult(testCase);
    Date end = new Date.now();
    int elapsed = end.difference(_testStarts[testCase.id]).inMilliseconds;
    if (testCase.stackTrace != null) {
      parentWindow.postMessage(
          _Message.text(_Message.STACK, elapsed, testCase.stackTrace), '*');
    }
    parentWindow.postMessage(
        _Message.text(testCase.result, elapsed, testCase.message), '*');
  }

  void onDone(int passed, int failed, int errors, List<TestCase> results,
              String uncaughtError) {
    _uninstallErrorHandler();
  }
}

/**
 * The parent configuration runs in the top-level window; it wraps the tests
 * in new functions that create child IFrames and run the real tests.
 */
class ParentInteractiveHtmlConfiguration extends HtmlConfiguration {
  Map<int,Date> _testStarts;


  /** The stack that was posted back from the child, if any. */
  String _stack;

  int _testTime;
  /**
   * Whether or not we have already wrapped the TestCase test functions
   * in new closures that instead create an IFrame and get it to run the
   * test.
   */
  bool _doneWrap = false;

  /**
   * We use this to make a single closure from _handleMessage so we
   * can remove the handler later.
   */
  Function _messageHandler;

  ParentInteractiveHtmlConfiguration() :
      _testStarts = new Map<int,Date>();

  // We need to block until the test is done, so we make a
  // dummy async callback that we will use to flag completion.
  Function completeTest = null;

  wrapTest(TestCase testCase) {
    String baseUrl = window.location.toString();
    String url = '${baseUrl}?t=${testCase.id}';
    return () {
      // Rebuild the child IFrame.
      Element childDiv = document.query('#child');
      childDiv.nodes.clear();
      IFrameElement child = new Element.html("""
          <iframe id='childFrame${testCase.id}' src='$url' style='display:none'>
          </iframe>""");
      childDiv.nodes.add(child);
      completeTest = expectAsync0((){ });
      // Kick off the test when the IFrame is loaded.
      child.on.load.add((e) {
        child.contentWindow.postMessage(_Message.text(_Message.START), '*');
      });
    };
  }

  void _handleMessage(MessageEvent e) {
    // Get the result, do any logging, then do a pass/fail.
    var msg = new _Message.fromString(e.data);
    if (msg.messageType == _Message.LOG) {
      logMessage(e.data);
    } else if (msg.messageType == _Message.STACK) {
      _stack = msg.body;
    } else {
      _testTime = msg.elapsed;
      logMessage(_Message.text(_Message.LOG, _testTime, 'Complete'));
      if (msg.messageType == _Message.PASS) {
        currentTestCase.pass();
      } else if (msg.messageType == _Message.FAIL) {
        currentTestCase.fail(msg.body, _stack);
      } else if (msg.messageType == _Message.ERROR) {
        currentTestCase.error(msg.body, _stack);
      }
      completeTest();
    }
  }

  void onInit() {
    _installErrorHandler();
    _messageHandler = _handleMessage; // We need to make just one closure.
    document.query('#group-divs').innerHtml = "";
  }

  void onStart() {
    _installErrorHandler();
    if (!_doneWrap) {
      _doneWrap = true;
      for (int i = 0; i < testCases.length; i++) {
        testCases[i].test = wrapTest(testCases[i]);
        testCases[i].setUp = null;
        testCases[i].tearDown = null;
      }
    }
    window.on.message.add(_messageHandler);
  }

  static final _notAlphaNumeric = new RegExp('[^a-z0-9A-Z]');

  String _stringToDomId(String s) {
    if (s.length == 0) {
      return '-None-';
    }
    return s.trim().replaceAll(_notAlphaNumeric, '-');
  }

  // Used for DOM element IDs for tests result list entries.
  static const _testIdPrefix = 'test-';
  // Used for DOM element IDs for test log message lists.
  static const _actionIdPrefix = 'act-';
  // Used for DOM element IDs for test checkboxes.
  static const _selectedIdPrefix = 'selected-';

  void onTestStart(TestCase testCase) {
    var id = testCase.id;
    _testStarts[testCase.id]= new Date.now();
    super.onTestStart(testCase);
    _stack = null;
    // Convert the group name to a DOM id.
    String groupId = _stringToDomId(testCase.currentGroup);
    // Get the div for the group. If it doesn't exist,
    // create it.
    var groupDiv = document.query('#$groupId');
    if (groupDiv == null) {
      groupDiv = new Element.html("""
          <div class='test-describe' id='$groupId'>
            <h2>
              <input type='checkbox' checked='true' class='groupselect'>
              Group: ${testCase.currentGroup}
            </h2>
            <ul class='tests'>
            </ul>
          </div>""");
      document.query('#group-divs').nodes.add(groupDiv);
      groupDiv.query('.groupselect').on.click.add((e) {
        var parent = document.query('#$groupId');
        InputElement cb = parent.query('.groupselect');
        var state = cb.checked;
        var tests = parent.query('.tests');
        for (Element t in tests.elements) {
          cb = t.query('.testselect') as InputElement;
          cb.checked = state;
          var testId = int.parse(t.id.substring(_testIdPrefix.length));
          if (state) {
            enableTest(testId);
          } else {
            disableTest(testId);
          }
        }
      });
    }
    var list = groupDiv.query('.tests');
    var testItem = list.query('#$_testIdPrefix$id');
    if (testItem == null) {
      // Create the li element for the test.
      testItem = new Element.html("""
          <li id='$_testIdPrefix$id' class='test-it status-pending'>
            <div class='test-info'>
              <p class='test-title'>
                <input type='checkbox' checked='true' class='testselect'
                    id='$_selectedIdPrefix$id'>
                <span class='test-label'>
                <span class='timer-result test-timer-result'></span>
                <span class='test-name closed'>${testCase.description}</span>
                </span>
              </p>
            </div>
            <div class='scrollpane'>
              <ol class='test-actions' id='$_actionIdPrefix$id'></ol>
            </div>
          </li>""");
      list.nodes.add(testItem);
      testItem.query('#$_selectedIdPrefix$id').on.change.add((e) {
        InputElement cb = testItem.query('#$_selectedIdPrefix$id');
        testCase.enabled = cb.checked;
      });
      testItem.query('.test-label').on.click.add((e) {
        var _testItem = document.query('#$_testIdPrefix$id');
        var _actions = _testItem.query('#$_actionIdPrefix$id');
        var _label = _testItem.query('.test-name');
        if (_actions.style.display == 'none') {
          _actions.style.display = 'table';
          _label.classes.remove('closed');
          _label.classes.add('open');
        } else {
          _actions.style.display = 'none';
          _label.classes.remove('open');
          _label.classes.add('closed');
        }
      });
    } else { // Reset the test element.
      testItem.classes.clear();
      testItem.classes.add('test-it');
      testItem.classes.add('status-pending');
      testItem.query('#$_actionIdPrefix$id').innerHtml = '';
    }
  }

  // Actually test logging is handled by the child, then posted
  // back to the parent. So here we know that the [message] argument
  // is in the format used by [_Message].
  void logTestCaseMessage(TestCase testCase, String message) {
    var msg = new _Message.fromString(message);
    if (msg.elapsed < 0) { // No associated test case.
      document.query('#otherlogs').nodes.add(
          new Element.html('<p>${msg.body}</p>'));
    } else {
      var actions = document.query('#$_testIdPrefix${testCase.id}').
          query('.test-actions');
      String elapsedText = msg.elapsed >= 0 ? "${msg.elapsed}ms" : "";
      actions.nodes.add(new Element.html(
          "<li style='list-style-stype:none>"
              "<div class='timer-result'>${elapsedText}</div>"
              "<div class='test-title'>${msg.body}</div>"
          "</li>"));
    }
  }

  void onTestResult(TestCase testCase) {
    if (!testCase.enabled) return;
    super.onTestResult(testCase);
    if (testCase.message != '') {
      logTestCaseMessage(testCase,
          _Message.text(_Message.LOG, -1, testCase.message));
    }
    int id = testCase.id;
    var testItem = document.query('#$_testIdPrefix$id');
    var timeSpan = testItem.query('.test-timer-result');
    timeSpan.text = '${_testTime}ms';
    // Convert status into what we need for our CSS.
    String result = 'status-error';
    if (testCase.result == 'pass') {
      result = 'status-success';
    } else if (testCase.result == 'fail') {
      result = 'status-failure';
    }
    testItem.classes.remove('status-pending');
    testItem.classes.add(result);
    // hide the actions
    var actions = testItem.query('.test-actions');
    for (Element e in actions.nodes) {
      e.classes.add(result);
    }
    actions.style.display = 'none';
  }

  void onDone(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    window.on.message.remove(_messageHandler);
    _uninstallErrorHandler();
    document.query('#busy').style.display = 'none';
    InputElement startButton = document.query('#start');
    startButton.disabled = false;
  }
}

/**
 * Add the divs to the DOM if they are not present. We have a 'controls'
 * div for control, 'specs' div with test results, a 'busy' div for the
 * animated GIF used to indicate tests are running, and a 'child' div to
 * hold the iframe for the test.
 */
void _prepareDom() {
  if (document.query('#control') == null) {
    // Use this as an opportunity for adding the CSS too.
    // I wanted to avoid having to include a css element explicitly
    // in the main html file. I considered moving all the styles
    // inline as attributes but that started getting very messy,
    // so we do it this way.
    document.body.nodes.add(new Element.html("<style>$_CSS</style>"));
    document.body.nodes.add(new Element.html(
        "<div id='control'>"
            "<input id='start' disabled='true' type='button' value='Run'>"
        "</div>"));
    document.query('#start').on.click.add((e) {
      InputElement startButton = document.query('#start');
      startButton.disabled = true;
      rerunTests();
    });
  }
  if (document.query('#otherlogs') == null) {
    document.body.nodes.add(new Element.html(
        "<div id='otherlogs'></div>"));
  }
  if (document.query('#specs') == null) {
    document.body.nodes.add(new Element.html(
        "<div id='specs'><div id='group-divs'></div></div>"));
  }
  if (document.query('#busy') == null) {
    document.body.nodes.add(new Element.html(
        "<div id='busy' style='display:none'><img src='googleballs.gif'>"
        "</img></div>"));
  }
  if (document.query('#child') == null) {
    document.body.nodes.add(new Element.html("<div id='child'></div>"));
  }
}

/**
 * Allocate a Configuration. We allocate either a parent or
 * child, depedning on whether the URL has a search part.
 */
void useInteractiveHtmlConfiguration() {
  if (window.location.search == '') { // This is the parent.
    _prepareDom();
    configure(new ParentInteractiveHtmlConfiguration());
  } else {
    configure(new ChildInteractiveHtmlConfiguration());
  }
}

String _CSS = """
body {
font-family: Arial, sans-serif;
margin: 0;
font-size: 14px;
}

#application h2,
#specs h2 {
margin: 0;
padding: 0.5em;
font-size: 1.1em;
}

#header,
#application,
.test-info,
.test-actions li {
overflow: hidden;
}

#application {
margin: 10px;
}

#application iframe {
width: 100%;
height: 758px;
}

#application iframe {
border: none;
}

#specs {
padding-top: 50px
}

.test-describe h2 {
border-top: 2px solid #BABAD1;
background-color: #efefef;
}

.tests,
.test-it ol,
.status-display {
margin: 0;
padding: 0;
}

.test-info {
margin-left: 1em;
margin-top: 0.5em;
border-radius: 8px 0 0 8px;
-webkit-border-radius: 8px 0 0 8px;
-moz-border-radius: 8px 0 0 8px;
cursor: pointer;
}

.test-info:hover .test-name {
text-decoration: underline;
}

.test-info .closed:before {
content: '\\25b8\\00A0';
}

.test-info .open:before {
content: '\\25be\\00A0';
font-weight: bold;
}

.test-it ol {
margin-left: 2.5em;
}

.status-display,
.status-display li {
float: right;
}

.status-display li {
padding: 5px 10px;
}

.timer-result,
.test-title {
display: inline-block;
margin: 0;
padding: 4px;
}

.test-actions .test-title,
.test-actions .test-result {
display: table-cell;
padding-left: 0.5em;
padding-right: 0.5em;
}

.test-it {
list-style-type: none;
}

.test-actions {
display: table;
}

.test-actions li {
display: table-row;
}

.timer-result {
width: 4em;
padding: 0 10px;
text-align: right;
font-family: monospace;
}

.test-it pre,
.test-actions pre {
clear: left;
color: black;
margin-left: 6em;
}

.test-describe {
margin: 5px 5px 10px 2em;
border-left: 1px solid #BABAD1;
border-right: 1px solid #BABAD1;
border-bottom: 1px solid #BABAD1;
padding-bottom: 0.5em;
}

.test-actions .status-pending .test-title:before {
content: \\'\\\\00bb\\\\00A0\\';
}

.scrollpane {
 max-height: 20em;
 overflow: auto;
}

#busy {
display: block;
}
/** Colors */

#header {
background-color: #F2C200;
}

#application {
border: 1px solid #BABAD1;
}

.status-pending .test-info {
background-color: #F9EEBC;
}

.status-success .test-info {
background-color: #B1D7A1;
}

.status-failure .test-info {
background-color: #FF8286;
}

.status-error .test-info {
background-color: black;
color: white;
}

.test-actions .status-success .test-title {
color: #30B30A;
}

.test-actions .status-failure .test-title {
color: #DF0000;
}

.test-actions .status-error .test-title {
color: black;
}

.test-actions .timer-result {
color: #888;
}

ul, menu, dir {
display: block;
list-style-type: disc;
-webkit-margin-before: 1em;
-webkit-margin-after: 1em;
-webkit-margin-start: 0px;
-webkit-margin-end: 0px;
-webkit-padding-start: 40px;
}

  """;
