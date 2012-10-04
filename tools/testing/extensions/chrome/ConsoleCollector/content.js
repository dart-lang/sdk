// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

window.addEventListener("message", function(event) {
console.log('Content script got '+event);
  if (event.source == window && event.data == "getMessages") {
console.log('Sending request to background page');
    chrome.extension.sendRequest({command: "getMessages"}, function(messages) {
console.log('Got response from background: '+ messages);
console.log('Posting response message');
      window.postMessage({ "type": "gotMessages", "messages" : messages}, "*");
    });
  }
}, false);

