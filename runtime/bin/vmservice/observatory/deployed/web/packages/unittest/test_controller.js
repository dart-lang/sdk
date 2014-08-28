// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Test controller logic - used by unit test harness to embed tests in
 * conent shell.
 */

// Clear the console before every test run - this is Firebug specific code.
if (typeof console == "object" && typeof console.clear == "function") {
  console.clear();
}

// Some tests may expect and have no way to suppress global errors.
var testExpectsGlobalError = false;
var testSuppressedGlobalErrors = [];

// Set window onerror to make sure that we catch test harness errors across all
// browsers.
window.onerror = function (message, url, lineNumber) {
  if (testExpectsGlobalError) {
    testSuppressedGlobalErrors.push({
      message: message
    });
    return;
  }
  if (url) {
    showErrorAndExit(
        "\n\n" + url + ":" + lineNumber + ":\n" + message + "\n\n");
  } else {
    showErrorAndExit(message);
  }
  window.postMessage('unittest-suite-external-error', '*');
};

// Start Dartium/content_shell, unless we are waiting for HTML Imports to load.
// HTML Imports allows a document to link to other HTMLs documents via
// <link rel=import>. It also allows for those other documents to contain
// <script> tags, which must be run before scripts on the main page.
// We have package:web_components to polyfill this feature, and it will handle
// starting Dartium/content_shell in that case. HTML Imports is used by Polymer,
// but it could be used by itself too. See the specification:
// https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/imports/index.html
if (navigator.webkitStartDart && !window.HTMLImports) {
  navigator.webkitStartDart();
}

// testRunner is provided by content shell.
// It is not available in browser tests.
var testRunner = window.testRunner || window.layoutTestController;

var waitForDone = false;

// Returns the driving window object if available
function getDriverWindow() {
  if (window != window.parent) {
    // We're running in an iframe.
    return window.parent;
  } else if (window.opener) {
    // We were opened by another window.
    return window.opener;
  }
  return null;
}

function notifyStart() {
  var driver = getDriverWindow();
  if (driver) {
    driver.postMessage("STARTING", "*");
  }
}
// We call notifyStart here to notify the encapsulating browser.
notifyStart();

function notifyDone() {
  if (testRunner) testRunner.notifyDone();

  // TODO(ricow): REMOVE, debug info, see issue 13292
  if (!testRunner) {
    printMessage('Calling notifyDone()');
  }
  // To support in browser launching of tests we post back start and result
  // messages to the window.opener.
  var driver = getDriverWindow();
  if (driver) {
    driver.postMessage(window.document.body.innerHTML, "*");
  }
}

function processMessage(msg) {
  if (typeof msg != 'string') return;
  // TODO(ricow): REMOVE, debug info, see issue 13292
  if (!testRunner) {
    // Filter out ShadowDOM polyfill messages which are random floats.
    if (msg != parseFloat(msg)) {
      printMessage('processMessage(): ' + msg);
    }
  }
  if (msg == 'unittest-suite-done') {
    notifyDone();
  } else if (msg == 'unittest-suite-wait-for-done') {
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
      printMessage('PASS');
      notifyDone();
    }
  } else if (msg == 'unittest-suite-success') {
    printMessage('PASS');
    notifyDone();
  } else if (msg == 'unittest-suite-fail') {
    showErrorAndExit('Some tests failed.');
  }
}

function onReceive(e) {
  processMessage(e.data);
}

if (testRunner) {
  testRunner.dumpAsText();
  testRunner.waitUntilDone();
}
window.addEventListener("message", onReceive, false);

function showErrorAndExit(message) {
  if (message) {
    printMessage('Error: ' + String(message));
  }
  // dart/tools/testing/test_runner.dart is looking for either PASS or
  // FAIL in a browser test's output.
  printMessage('FAIL');
  notifyDone();
}

function onLoad(e) {
  // needed for dartium compilation errors.
  if (window.compilationError) {
    showErrorAndExit(window.compilationError);
  }
}

window.addEventListener("DOMContentLoaded", onLoad, false);

// Note: before renaming this function, note that it is also included in an
// inlined error handler in the HTML files that wrap DRT tests.
// See: tools/testing/dart/browser_test.dart
function externalError(e) {
  // needed for dartium compilation errors.
  showErrorAndExit(e && e.message);
  window.postMessage('unittest-suite-external-error', '*');
}

document.addEventListener('readystatechange', function () {
  if (document.readyState != "loaded") return;
  // If 'startedDartTest' is not set, that means that the test did not have
  // a chance to load. This will happen when a load error occurs in the VM.
  // Give the machine time to start up.
  setTimeout(function() {
    // A window.postMessage might have been enqueued after this timeout.
    // Just sleep another time to give the browser the time to process the
    // posted message.
    setTimeout(function() {
      if (testRunner && !testRunner.startedDartTest) {
        notifyDone();
      }
    }, 0);
  }, 50);
});

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
//   unittest-suite-success:  signals the end of an asynchrounous test
//
// These messages are used to communicate with the test and will be posted so
// [processMessage] above can see it.
function dartPrint(msg) {
  if ((msg === 'unittest-suite-success')
      || (msg === 'unittest-suite-done')
      || (msg === 'unittest-suite-wait-for-done')
      || (msg === 'dart-calling-main')
      || (msg === 'dart-main-done')) {
    window.postMessage(msg, '*');
    return;
  }
  printMessage(msg);
}

// Prints 'msg' to the console (if available) and to the body of the html
// document.
function printMessage(msg) {
  if (typeof console === 'object') console.warn(msg);
  var pre = document.createElement('pre');
  pre.appendChild(document.createTextNode(String(msg)));
  document.body.appendChild(pre);
  document.body.appendChild(document.createTextNode('\n'));
}

// dart2js will generate code to call this function instead of calling
// Dart [main] directly. The argument is a closure that invokes main.
function dartMainRunner(main) {
  dartPrint('dart-calling-main');
  try {
    main();
  } catch (e) {
    dartPrint(e);
    if (e.stack) dartPrint(e.stack);
    window.postMessage('unittest-suite-fail', '*');
    return;
  }
  dartPrint('dart-main-done');
}
