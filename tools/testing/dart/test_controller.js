// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
 * The communication protocol between test_controller.js and the driving
 * page are JSON encoded messages of the following form:
 *   message = {
 *      is_first_message: true/false,
 *      is_status_update: true/false,
 *      is_done: true/false,
 *      message: message_content,
 *   }
 *
 * The first message should have [is_first_message] set, the last message
 * should have [is_done] set. Status updates should have [is_status_update] set.
 *
 * The [message_content] can be be any content. In our case it will a list of
 * events encoded in JSON. See the next comment further down about what an event
 * is.
 */

/*
 * We will collect testing driver specific events here instead of printing
 * them to the DOM.
 * Every entry will look like this:
 *   {
 *     'type' : 'sync_exception' / 'window_onerror' / 'script_onerror' / 'print'
 *              'window_compilationerror' / 'message_received' / 'dom' / 'debug'
 *     'value' : 'some content',
 *     'timestamp' : TimestampInMs,
 *   }
 *
 * If the type is 'sync_exception', it will have an additional 'stack_trace'
 * field whose value is a string.
 */
var recordedEventList = [];
var timestampOfFirstEvent = null;

var STATUS_UPDATE_INTERVAL = 10000;

function getCurrentTimestamp() {
  if (timestampOfFirstEvent == null) {
    timestampOfFirstEvent = new Date().getTime();
  }
  return (new Date().getTime() - timestampOfFirstEvent) / 1000.0;
}

function stringifyEvent(event) {
  return JSON.stringify(event, null, 2);
}

function recordEvent(type, value, stackTrace) {
  var event = {
    type: type,
    value: value,
    timestamp: getCurrentTimestamp()
  };

  if (stackTrace !== undefined) {
    event['stack_trace'] = stackTrace;
  }

  recordedEventList.push(event);
  printToConsole(stringifyEvent(event));
}

function clearConsole() {
  // Clear the console before every test run - this is Firebug specific code.
  if (typeof console == 'object' && typeof console.clear == 'function') {
    console.clear();
  }
}

function printToDOM(message) {
  var pre = document.createElement('pre');
  pre.appendChild(document.createTextNode(String(message)));
  document.body.appendChild(pre);
  document.body.appendChild(document.createTextNode('\n'));
}

function printToConsole(message) {
  var consoleAvailable = typeof console === 'object';

  if (consoleAvailable) {
    console.log(message);
  }
}

clearConsole();

// Some tests may expect and have no way to suppress global errors.
var testExpectsGlobalError = false;
var testSuppressedGlobalErrors = [];

// Set window onerror to make sure that we catch test harness errors across all
// browsers.
window.onerror = function (message, url, line, column, error) {
  if (url) {
    message = ('window.onerror called: \n\n' +
        url + ':' + line + ':' + column + ':\n' + message + '\n\n');
  }
  if (testExpectsGlobalError) {
    testSuppressedGlobalErrors.push({
      message: message
    });
    return;
  }

  var stack = getStackTrace(error);
  recordEvent('window_onerror', message, stack);
  notifyDone('FAIL');
};

// testRunner is provided by content shell.
// It is not available in browser tests.
var testRunner = window.testRunner || window.layoutTestController;
var isContentShell = testRunner;

var waitForDone = false;

var driverWindowCached = false;
var driverWindow;
var reportingDriverWindowError = false;

// This can be set to a function that takes an error and produces a stringified
// stack trace for the error. DDC sets this to clean up its stack traces before
// reporting them.
var testErrorToStackTrace = null;

function getStackTrace(error) {
  if (testErrorToStackTrace) {
    return testErrorToStackTrace(error);
  } else {
    return error.stack.toString();
  }
}

// Returns the driving window object if available
// This function occasionally returns null instead of the
// parent on Android content shell, so we cache the value
// to get a consistent answer.
function getDriverWindow() {
  if (window != window.parent) {
    // We're running in an iframe.
    result = window.parent;
  } else if (window.opener) {
    // We were opened by another window.
    result = window.opener;
  } else {
    result = null;
  }
  if (driverWindowCached) {
    if (result != driverWindow) {
      recordEvent('debug', 'Driver windows changed: was null == ' +
           (driverWindow == null) + ', is null == ' + (result == null));
      // notifyDone calls back into this function multiple times.  Avoid loop.
      if (!reportingDriverWindowError) {
        reportingDriverWindowError = true;
        notifyDone('FAIL');
      }
    }
  } else {
    driverWindowCached = true;
    driverWindow = result;
  }
  return driverWindow;
}

function usingBrowserController() {
  return getDriverWindow() != null;
}

function buildDomEvent() {
  return {
      type: 'dom',
      value: '' + window.document.documentElement.innerHTML,
      timestamp: getCurrentTimestamp()
  };
}

function notifyUpdate(testOutcome, isFirstMessage, isStatusUpdate, isDone) {
  // If we are not using the browser controller (e.g. in the none-drt
  // configuration), we need to print 'testOutcome' as it is.
  if (isDone && !usingBrowserController()) {
    if (isContentShell) {
      // We need this, since test.dart is looking for 'FAIL\n', 'PASS\n' in the
      // DOM output of content shell.
      printToDOM(testOutcome);
    } else {
      printToConsole('Test outcome: ' + testOutcome);
    }
  } else if (usingBrowserController()) {
    // To support in browser launching of tests we post back start and result
    // messages to the window.opener.
    var driver = getDriverWindow();

    recordEvent('debug', 'Sending events to driver page (isFirstMessage = ' +
                isFirstMessage + ', isStatusUpdate = ' +
                isStatusUpdate + ', isDone = ' + isDone + ')');
    // Post the DOM and all events that happened.
    var events = recordedEventList.slice(0);
    events.push(buildDomEvent());

    var message = JSON.stringify(events);
    driver.postMessage(
        JSON.stringify({
          message: message,
          is_first_message: isFirstMessage,
          is_status_update: isStatusUpdate,
          is_done: isDone
        }), '*');
  }
  if (isDone) {
    if (testRunner) testRunner.notifyDone();
  }
}

function notifyDone(testOutcome) {
  notifyUpdate(testOutcome, false, false, true);
}

// Repeatedly send back the current status of this test.
function sendStatusUpdate(isFirstMessage) {
  notifyUpdate('', isFirstMessage, true, false);
  setTimeout(function() {sendStatusUpdate(false)}, STATUS_UPDATE_INTERVAL);
}

// We call notifyStart here to notify the encapsulating browser.
recordEvent('debug', 'test_controller.js started');
sendStatusUpdate(true);

function processMessage(msg) {
  // Filter out ShadowDOM polyfill messages which are random floats.
  if (msg != parseFloat(msg)) {
    recordEvent('message_received', '' + msg);
  }
  if (typeof msg != 'string') return;
  if (msg == 'unittest-suite-wait-for-done') {
    waitForDone = true;
    if (testRunner) {
      testRunner.startedDartTest = true;
    }
  } else if (msg == 'dart-calling-main') {
    if (testRunner) {
      testRunner.startedDartTest = true;
    }
  } else if (msg == 'dart-main-done') {
    if (!waitForDone) {
      notifyDone('PASS');
    }
  } else if (msg == 'unittest-suite-success' ||
             msg == 'unittest-suite-done') {
    notifyDone('PASS');
  } else if (msg == 'unittest-suite-fail') {
    notifyDone('FAIL');
  }
}

function onReceive(e) {
  processMessage(e.data);
}

if (testRunner) {
  testRunner.dumpAsText();
  testRunner.waitUntilDone();
}
window.addEventListener('message', onReceive, false);

function onLoad(e) {
  // needed for dartium compilation errors.
  if (window.compilationError) {
    recordEvent('window_compilationerror',
        'DOMContentLoaded event: window.compilationError = ' +
        calledwindow.compilationError);
    notifyDone('FAIL');
  }
}

window.addEventListener('DOMContentLoaded', onLoad, false);

// Note: before renaming this function, note that it is also included in an
// inlined error handler in generated HTML files, and manually in tests that
// include an HTML file.
// See: tools/testing/dart/browser_test.dart
function scriptTagOnErrorCallback(e) {
  var message = e && e.message;
  recordEvent('script_onerror', 'script.onError called: ' + message);
  notifyDone('FAIL');
}

// dart2js will generate code to call this function to handle the Dart
// [print] method.
//
// dartium will invoke this method for [print] calls if the environment variable
// "DART_FORWARDING_PRINT" was set when launching dartium.
//
// Our tests will be wrapped, so we can detect when [main] is called and when
// it has ended.
// The wrapping happens either via "dartMainRunner" (for dart2js) or wrapped
// tests for dartium.
//
// The following messages are handled specially:
//   dart-calling-main:  signals that the dart [main] function will be invoked
//   dart-main-done:  signals that the dart [main] function has finished
//   unittest-suite-wait-for-done:  signals the start of an asynchronous test
//   unittest-suite-success:  signals the end of an asynchronous test
//   unittest-suite-fail:  signals that the asynchronous test failed
//   unittest-suite-done:  signals the end of an asynchronous test, the outcome
//                         is unknown
//
// These messages are used to communicate with the test and will be posted so
// [processMessage] above can see it.
function dartPrint(message) {
  recordEvent('print', message);
  if ((message === 'unittest-suite-wait-for-done') ||
      (message === 'unittest-suite-success') ||
      (message === 'unittest-suite-fail') ||
      (message === 'unittest-suite-done') ||
      (message === 'dart-calling-main') ||
      (message === 'dart-main-done')) {
    // We have to do this asynchronously, in case error messages are
    // already in the message queue.
    window.postMessage(message, '*');
    return;
  }
}

// dart2js will generate code to call this function instead of calling
// Dart [main] directly. The argument is a closure that invokes main.
function dartMainRunner(main) {
  dartPrint('dart-calling-main');
  try {
    main();
  } catch (error) {
    var stack = getStackTrace(error);
    recordEvent('sync_exception', error.toString(), stack);
    notifyDone('FAIL');
    return;
  }
  dartPrint('dart-main-done');
}
