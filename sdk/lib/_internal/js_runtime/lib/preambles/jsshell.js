// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Javascript preamble, that lets the output of dart2js run on JSShell.

(function(self) {
  // Using strict mode to avoid accidentally defining global variables.
  "use strict"; // Should be first statement of this function.

  // Location (Uri.base)

  var workingDirectory = os.getenv("PWD");

  // Global properties. "self" refers to the global object, so adding a
  // property to "self" defines a global variable.
  self.self = self;

  self.location = { href: "file://" + workingDirectory + "/" };

   function computeCurrentScript() {
    try {
      throw new Error();
    } catch(e) {
      var stack = e.stack;
      print(stack);
      // The jsshell stack looks like:
      //   computeCurrentScript@...preambles/jsshell.js:23:13
      //   self.document.currentScript@...preambles/jsshell.js:53:37
      //   @/tmp/foo.js:308:1
      //   @/tmp/foo.js:303:1
      //   @/tmp/foo.js:5:1
      var re = new RegExp("^.*@(.*):[0-9]*:[0-9]*$", "mg");
      var lastMatch = null;
      do {
        var match = re.exec(stack);
        if (match != null) lastMatch = match;
      } while (match != null);
      return lastMatch[1];
    }
  }

  // Adding a 'document' is dangerous since it invalidates the 'typeof document'
  // test to see if we are running in the browser. It means that the runtime
  // needs to do more precise checks.
  // Note that we can't run "currentScript" right away, since that would give
  // us the location of the preamble file. Instead we wait for the first access
  // which should happen just before invoking main. At this point we are in
  // the main file and setting the currentScript property is correct.
  // Note that we cannot use `thisFileName()`, since that would give us the
  // preamble and not the script file.
  var cachedCurrentScript = null;
  self.document = { get currentScript() {
      if (cachedCurrentScript == null) {
        cachedCurrentScript = {src: computeCurrentScript()};
      }
      return cachedCurrentScript;
    }
  };

  // Support for deferred loading.
  self.dartDeferredLibraryLoader = function(uri, successCallback, errorCallback) {
    try {
      load(uri);
      successCallback();
    } catch (error) {
      errorCallback(error);
    }
  };

  // Mock cryptographically secure random by using plain random.
  self.crypto = {getRandomValues: function(array) {
    for (var i = 0; i < array.length; i++) {
      array[i] = Math.random() * 256;
    }
  }};
})(this)

var getKeys = function(obj){
   var keys = [];
   for(var key in obj){
      keys.push(key);
   }
   return keys;
}
