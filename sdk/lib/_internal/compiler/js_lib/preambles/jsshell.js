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

  // Support for deferred loading.
  self.dartDeferredLibraryLoader = function(uri, successCallback, errorCallback) {
    try {
      load(uri);
      successCallback();
    } catch (error) {
      errorCallback(error);
    }
  };
})(this)

var getKeys = function(obj){
   var keys = [];
   for(var key in obj){
      keys.push(key);
   }
   return keys;
}
