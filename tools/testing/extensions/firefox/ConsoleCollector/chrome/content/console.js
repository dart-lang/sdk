// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This Firefox add-on exposes the Javascript console contents to Javascript
// running in the browser. Once this is installed there will be a new
// window.ConsoleCollector object with read() and clear() functions.

var ConsoleCollector = {};
 
(function() {
  // An array for collecting the messages.
  var messages = [];

  // Add a console message to the collection.
  this.add = function(message) {
    messages.push(message);
  };

  // Read the message collection. As a side effect we clear the message list.
  this.read = function(type) {
    var rtn = [];
    for (var i = 0; i < messages.length; i++) {
      var message = messages[i];
      if (message.errorMessage) {
        rtn.push({ 'time' : message.timeStamp,
                 'source' : message.sourceName,
                 'line': message.lineNumber,
                 'column': message.columnNumber,
                 'category': message.category,
                 'message' : message.errorMessage });
      }
    }
    messages = [];
    return rtn;
  };

  // Clear the message list.
  this.clear = function() {
    messages = [];
  };
}).apply(ConsoleCollector);

// A Console Listener.
// See https://developer.mozilla.org/en-US/docs/Console_service for
// details.
(function() {

  var consoleService;

  var consoleListener = {
    observe: function(e) {
      try {
        var message = e.QueryInterface(Components.interfaces.nsIScriptError);
        ConsoleCollector.add(message);
      } catch (exception) {
        ConsoleCollector.add(e);
      }      
    },

    QueryInterface: function (iid) {
      if (!iid.equals(Components.interfaces.nsIConsoleListener) &&
      !iid.equals(Components.interfaces.nsISupports)) {
        throw Components.results.NS_ERROR_NO_INTERFACE;
      }
      return this;
    }
  };
  
  // Start collecting console messages.
  function initialize(event) {
    consoleService = Components.classes['@mozilla.org/consoleservice;1']
                   .getService(Components.interfaces.nsIConsoleService);
    if (consoleService) {
      consoleService.registerListener(consoleListener); 
    }                              
    // Add the handler for hooking in to each page's DOM. This handler
    // is for each "gBrowser", representing a tab/window.
    window.getBrowser().addEventListener("load", onPageLoad, true);
  }

  // Stop collecting console messages.
  function shutdown(event) {
    window.getBrowser().removeEventListener("load", onPageLoad);
    consoleService.unregisterListener(consoleListener);   
    ConsoleCollector.clear();
  }
  
  // Hook the ConsoleCollector into the DOM as window.ConsoleCollector.
  var onPageLoad = function(e) {
    var win = e.originalTarget.defaultView;
    if (win) {
      win.wrappedJSObject.ConsoleCollector = ConsoleCollector;
    }
  };

  // Add the handlers to initialize the add-on and shut it down.
  // These handlers are for the application as a whole.
  window.addEventListener('load', initialize, false);
  window.addEventListener('unload', shutdown, false);
}());



