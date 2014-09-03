// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Coverage controller logic - used by coverage test harness to embed tests in
 * content shell and extract coverage information.
 */

var LONG_LINE = 60000;

function onReceive(e) {
  if (e.data == 'unittest-suite-done') {
    var s = JSON.stringify(top._$jscoverage);
    var res = '';
    // conent shell has a bug on lines longer than 2^16, so we split them
    while (s.length > LONG_LINE) {
      res += s.substr(0, LONG_LINE) + '<br>\n';
      s = s.substr(LONG_LINE);
    }
    res += s;
    window.document.body.innerHTML = res;
    window.layoutTestController.notifyDone();
  }
}

if (window.layoutTestController) {
  window.layoutTestController.dumpAsText();
  window.layoutTestController.waitUntilDone();
  window.addEventListener("message", onReceive, false);
}
