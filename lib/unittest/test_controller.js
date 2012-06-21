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

function processMessage(msg) {
  if (window.layoutTestController) {
    if (msg == 'unittest-suite-done') {
      window.layoutTestController.notifyDone();
    } else if (msg == 'unittest-suite-wait-for-done') {
      window.layoutTestController.startedDartTest = true;
    }
  }
}

function onReceive(e) {
  processMessage(e.data);
}

if (window.layoutTestController) {
  window.layoutTestController.dumpAsText();
  window.layoutTestController.waitUntilDone();
}
window.addEventListener("message", onReceive, false);

function showErrorAndExit(message) {
  if (message) {
    var element = document.createElement('pre');
    element.innerHTML = message;
    document.body.appendChild(element);
  }
  if (window.layoutTestController) {
    window.layoutTestController.notifyDone();
  }
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

document.onreadystatechange = function() {
  if (document.readyState != "loaded") return;
  // If 'startedDartTest' is not set, that means that the test did not have
  // a chance to load. This will happen when a load error occurs in the VM.
  // Give the machine time to start up.
  setTimeout(function() {
    // A window.postMessage might have been enqueued after this timeout.
    // Just sleep another time to give the browser the time to process the
    // posted message.
    setTimeout(function() {
      if (layoutTestController && !layoutTestController.startedDartTest) {
        layoutTestController.notifyDone();
      }
    }, 0);
  }, 50);
};
