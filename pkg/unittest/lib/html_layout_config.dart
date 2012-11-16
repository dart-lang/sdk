// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A configuration for running layoutr tests with testrunner.
 * This configuration is similar to the interactive_html_config
 * as it runs each test in its own IFrame. However, where the former
 * recreated the IFrame for each test, here the IFrames are preserved.
 * Furthermore we post a message on completion.
 */
library html_layout_config;

import 'dart:html';
import 'dart:math';
import 'unittest.dart';

/** The messages exchanged between parent and child. */
// TODO(gram) At some point postMessage was supposed to support
// sending arrays and maps. When it does we can get rid of the encoding/
// decoding of messages as string.
class _Message {
  static final START = 'start';
  static final LOG = 'log';
  static final STACK = 'stack';
  static final PASS = 'pass';
  static final FAIL = 'fail';
  static final ERROR = 'error';

  String messageType;
  int elapsed;
  String body;

  static String text(String messageType,
                     [int elapsed = 0, String body = '']) =>
      '$messageType $elapsed $body';

  _Message(this.messageType, [this.elapsed = 0, this.body = '']);

  _Message.fromString(String msg) {
    // The format of a message is '<type> <elapsedTime> <body>'.
    // If we don't get a type we default to a 'log' type.
    var messageParser = new RegExp('\([a-z]*\) \([0-9]*\) \(.*\)');
    Match match = messageParser.firstMatch(msg);
    if (match == null) {
      messageType = 'log';
      elapsed = 0;
      body = msg;
    } else {
      messageType = match.group(1);
      elapsed = int.parse(match.group(2));
      body = match.group(3);
    }
  }

  String toString() => text(messageType, elapsed, body);
}

/**
 * The child configuration that is used to run individual tests in
 * an IFrame and post the results back to the parent. In principle
 * this can run more than one test in the IFrame but currently only
 * one is used.
 */
class ChildHtmlConfiguration extends Configuration {
  get name => 'ChildHtmlConfiguration';
  // TODO(rnystrom): Get rid of this if we get canonical closures for methods.
  EventListener _onErrorClosure;

  /** The window to which results must be posted. */
  Window parentWindow;

  /** The time at which tests start. */
  Map<int,Date> _testStarts;

  ChildHtmlConfiguration() :
      _testStarts = new Map<int,Date>();

  /** Don't start running tests automatically. */
  get autoStart => false;

  void onInit() {
    _onErrorClosure =
        (e) => handleExternalError(e, '(DOM callback has errors)');

    /**
     *  The parent posts a 'start' message to kick things off,
     *  which is handled by this handler. It saves the parent
     *  window, gets the test ID from the query parameter in the
     *  IFrame URL, sets that as a solo test and starts test execution.
     */
    window.on.message.add((MessageEvent e) {
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
    // Listen for uncaught errors.
    window.on.error.add(_onErrorClosure);
  }

  /** Record the start time of the test. */
  void onTestStart(TestCase testCase) {
    super.onTestStart(testCase);
    _testStarts[testCase.id]= new Date.now();
  }

  /**
   * Tests can call [log] for diagnostic output. These log
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
   * Get the elapsed time for the test, and post the test result
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
    window.on.error.remove(_onErrorClosure);
  }
}

/**
 * The parent configuration runs in the top-level window; it wraps the tests
 * in new functions that create child IFrames and run the real tests.
 */
class ParentHtmlConfiguration extends Configuration {
  get autoStart => false;
  get name => 'ParentHtmlConfiguration';
  Map<int,Date> _testStarts;
  // TODO(rnystrom): Get rid of this if we get canonical closures for methods.
  EventListener _onErrorClosure;

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

  ParentHtmlConfiguration() :
      _testStarts = new Map<int,Date>();

  // We need to block until the test is done, so we make a
  // dummy async callback that we will use to flag completion.
  Function completeTest = null;

  wrapTest(TestCase testCase) {
    String baseUrl = window.location.toString();
    String url = '${baseUrl}?t=${testCase.id}';
    return () {
      // Add the child IFrame.
      Element childDiv = document.query('#child');
      var label = new Element.html(
          "<pre id='result${testCase.id}'>${testCase.description}</pre>");
      IFrameElement child = new Element.html("""
          <iframe id='childFrame${testCase.id}' src='$url'>
          </iframe>""");
      childDiv.nodes.add(label);
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
    _messageHandler = _handleMessage; // We need to make just one closure.
    _onErrorClosure =
        (e) => handleExternalError(e, '(DOM callback has errors)');
  }

  void onStart() {
    // Listen for uncaught errors.
    window.on.error.add(_onErrorClosure);
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

  void onTestStart(TestCase testCase) {
    var id = testCase.id;
    _testStarts[testCase.id]= new Date.now();
    super.onTestStart(testCase);
    _stack = null;
  }

  // Actually test logging is handled by the child, then posted
  // back to the parent. So here we know that the [message] argument
  // is in the format used by [_Message].
  void logTestCaseMessage(TestCase testCase, String message) {
    var msg = new _Message.fromString(message);
    document.query('#otherlogs').nodes.add(
          new Element.html('<p>${msg.body}</p>'));
  }

  void onTestResult(TestCase testCase) {
    if (!testCase.enabled) return;
    super.onTestResult(testCase);
    document.query('#result${testCase.id}').text =
        '${testCase.result}:${testCase.runningTime.inMilliseconds}:'
        '${testCase.description}//${testCase.message}';
  }

  void onDone(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    window.on.message.remove(_messageHandler);
    window.on.error.remove(_onErrorClosure);
    window.postMessage('done', '*'); // Unblock DRT
  }
}

/**
 * Add the divs to the DOM if they are not present.
 */
void _prepareDom() {
  if (document.query('#otherlogs') == null) {
    document.body.nodes.add(new Element.html(
        "<div id='otherlogs'></div>"));
  }
  if (document.query('#child') == null) {
    document.body.nodes.add(new Element.html("<div id='child'></div>"));
  }
}

/**
 * Allocate a Configuration. We allocate either a parent or
 * child, depending on whether the URL has a search part.
 */
void useHtmlLayoutConfiguration() {
  if (window.location.search == '') { // This is the parent.
    _prepareDom();
    configure(new ParentHtmlConfiguration());
  } else {
    configure(new ChildHtmlConfiguration());
  }
}

