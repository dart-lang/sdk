// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is the background window. It can access the necessary APIs to get
 * at the console messages. It can only communicate with the content
 * window through message passing.
 *
 * There is no way to query the console messages, as such, but we can
 * set up a handler that is called when there are console messages. This 
 * will be called with any console messages already present, so it can be set
 * up after the fact. However, if there are no messages it won't be called.
 * To handle the end of the messages (or no messages) we have to use a 
 * sentinel message that is logged by the content page.
 */
var version = "1.0";
var messages = []; // An array that we can put messages in.
var debuggeeId; // An object that identifies the browser tab we are talking to.
var callback; // For passing back the response to the content window.
var timer; // To time out if no messages are available.

/**
 * When we have collected all the messages, we send them back to the
 * content page via the callback, turn off message collection, and
 * detach the debugger from the browser tab.
 */
function allDone() {
  callback(messages); 
  chrome.debugger.sendCommand(debuggeeId, "Console.clearMessages", {},
      function() {
        chrome.debugger.sendCommand(debuggeeId, "Console.disable", {},
            function() {});
        chrome.debugger.detach(debuggeeId, function() {});
  });
  messages = [];
}

/**
 * Debugger event handler. We only care about console.messageAdded
 * events, in which case we add a new message object with the fields
 * we care about to our messages array.
 */
function onEvent(debuggeeId, method, params) {
  var tabId = debuggeeId.tabId;
  if (method == "Console.messageAdded") {
    var msg = params.message;
    // More fields are available if we want them later. See
    // https://developers.google.com/chrome-developer-tools/docs/protocol/1.0/console#type-ConsoleMessage
    if (msg.text == 'getMessages/end') {
      allDone();
    } else {
      messages.push({"source":msg.url, "line": msg.line,
          "category":msg.source, "message":msg.text });
    }
  }
}

/**
 * Handle requests sent by the content script. We save the callback,
 * get the window and tab that is currently active, attach the 
 * debugger to that tab, and then turn on console message event 
 * handling, which will result in onEvent calls for each console 
 * message, including the ones that are already present in the console.
 */
function onRequest(request, sender, sendResponse) {
  if (request.command == "getMessages") {
    callback = sendResponse;
    chrome.windows.getCurrent(function(win) {
      chrome.tabs.getSelected(win.id, function(tab) {
        debuggeeId = {tabId:tab.id};
        chrome.debugger.attach(debuggeeId, version, function() {
          if (chrome.extension.lastError) {
            // Attach failed; send an empty response.
            callback([]);
          } else {
            chrome.debugger.sendCommand(debuggeeId, "Console.enable", {},
              function() {});
            //timer = setTimeout(allDone, 1000);
          }
        });
      });
    });
  }
}

// Set up the general handler for debug events.
chrome.debugger.onEvent.addListener(onEvent);
// Listen for the content script to send a message to the background page.
chrome.extension.onRequest.addListener(onRequest);
