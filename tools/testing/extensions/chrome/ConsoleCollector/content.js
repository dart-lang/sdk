// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is the content page script. This runs in the context of the browser
 * page, and communicates with the background page by relaying a getMessages
 * request, and the forwarding the messages back to the browser page as a
 * gotMessages message.
 */
window.addEventListener("message", function(event) {
  if (event.source == window && event.data == "getMessages") {
    // Log a special sentinel message to mark the end of the messages.
    console.log('getMessages/end');
    chrome.extension.sendRequest({command: "getMessages"}, function(messages) {
      window.postMessage({ "type": "gotMessages", "messages" : messages}, "*");
    });
  }
}, false);
