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

function onLoad(e) {
  // needed for dartium compilation errors.
  if (window.compilationError) {
    var element = document.createElement('pre');
    element.innerHTML = window.compilationError;
    document.body.appendChild(element);
    window.layoutTestController.notifyDone();
    return;
  }
}

window.addEventListener("DOMContentLoaded", onLoad, false);
