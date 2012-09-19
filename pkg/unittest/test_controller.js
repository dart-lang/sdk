// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Test controller logic - used by unit test harness to embed tests in
 * DumpRenderTree.
 */

if (navigator.webkitStartDart) {
  navigator.webkitStartDart();
}

// testRunner is provided by DRT or WebKit's layout tests.
// It is not available in selenium tests.
var testRunner = window.testRunner || window.layoutTestController;

var waitForDone = false;

function processMessage(msg) {
  if (typeof msg != 'string') return;
  if (msg == 'unittest-suite-done') {
    if (testRunner) testRunner.notifyDone();
  } else if (msg == 'unittest-suite-wait-for-done') {
    waitForDone = true;
    if (testRunner) testRunner.startedDartTest = true;
  } else if (msg == 'dart-calling-main') {
    if (testRunner) testRunner.startedDartTest = true;
  } else if (msg == 'dart-main-done') {
    if (!waitForDone) {
      window.postMessage('unittest-suite-success', '*');
    }
  } else if (msg == 'unittest-suite-success') {
    dartPrint('PASS');
    if (testRunner) testRunner.notifyDone();
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
    dartPrint('Error: ' + String(message));
  }
  // dart/tools/testing/run_selenium.py is looking for either PASS or
  // FAIL and will continue polling until one of these words show up.
  dartPrint('FAIL');
  if (testRunner) testRunner.notifyDone();
}

function onLoad(e) {
  // needed for dartium compilation errors.
  if (window.compilationError) {
    showErrorAndExit(window.compilationError);
  }
}

window.addEventListener("DOMContentLoaded", onLoad, false);

// If nobody intercepts the error, finish the test.
window.addEventListener("error", function(e) {
  // needed for dartium compilation errors.
  showErrorAndExit(e && e.message);
}, false);

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
        testRunner.notifyDone();
      }
    }, 0);
  }, 50);
});

// dart2js will generate code to call this function to handle the Dart
// [print] method. The base [Configuration] (config.html) calls
// [print] with the secret messages "unittest-suite-success" and
// "unittest-suite-wait-for-done". These messages are then posted so
// processMessage above will see them.
function dartPrint(msg) {
  if ((msg === 'unittest-suite-success')
      || (msg === 'unittest-suite-wait-for-done')) {
    window.postMessage(msg, '*');
    return;
  }
  var pre = document.createElement("pre");
  pre.appendChild(document.createTextNode(String(msg)));
  document.body.appendChild(pre);
}

// dart2js will generate code to call this function instead of calling
// Dart [main] directly. The argument is a closure that invokes main.
function dartMainRunner(main) {
  window.postMessage('dart-calling-main', '*');
  try {
    main();
  } catch (e) {
    window.postMessage('unittest-suite-fail', '*');
    return;
  }
  window.postMessage('dart-main-done', '*');
}
