var _js_primitives;
(function(_js_primitives) {
  'use strict';
  // Function printString: (String) → void
  function printString(string) {
    if (typeof dartPrint == "function") {
      dartPrint(string);
      return;
    }
    if (dart.notNull(typeof console == "object") && dart.notNull(typeof console.log != "undefined")) {
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
  // Exports:
  _js_primitives.printString = printString;
})(_js_primitives || (_js_primitives = {}));
