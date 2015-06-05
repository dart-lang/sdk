dart.library('dart/_js_primitives', null, /* Imports */[
  'dart/core'
], /* Lazy imports */[
], function(exports, core) {
  'use strict';
  function printString(string) {
    if (typeof dartPrint == "function") {
      dartPrint(string);
      return;
    }
    if (typeof console == "object" && typeof console.log != "undefined") {
      console.log(string);
      return;
    }
    if (typeof window == "object") {
      return;
    }
    if (typeof print == "function") {
      print(string);
      return;
    }
    throw "Unable to print message: " + String(string);
  }
  dart.fn(printString, dart.void, [core.String]);
  // Exports:
  exports.printString = printString;
});
