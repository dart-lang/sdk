// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Handles requests sent by the content script.
 */
function onRequest(request, sender, sendResponse) {
  if (request.command == "getMessages") {
    chrome.experimental.devtools.console.getMessages(function (m) {
      sendResponse(m);
    });
  }
}

// Listen for the content script to send a message to the background page.
chrome.extension.onRequest.addListener(onRequest);

