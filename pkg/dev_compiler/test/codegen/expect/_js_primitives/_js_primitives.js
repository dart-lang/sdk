var _js_primitives;
(function(_js_primitives) {
  'use strict';
  // Function printString: (String) → void
  function printString(string) {
    if (_foreign_helper.JS('bool', 'typeof dartPrint == "function"')) {
      _foreign_helper.JS('void', 'dartPrint(#)', string);
      return;
    }
    if (dart.dbinary(_foreign_helper.JS('bool', 'typeof console == "object"'), '&&', _foreign_helper.JS('bool', 'typeof console.log != "undefined"'))) {
      _foreign_helper.JS('void', 'console.log(#)', string);
      return;
    }
    if (_foreign_helper.JS('bool', 'typeof window == "object"')) {
      return;
    }
    if (_foreign_helper.JS('bool', 'typeof print == "function"')) {
      _foreign_helper.JS('void', 'print(#)', string);
      return;
    }
    _foreign_helper.JS('void', 'throw "Unable to print message: " + String(#)', string);
  }
  // Exports:
  _js_primitives.printString = printString;
})(_js_primitives || (_js_primitives = {}));
