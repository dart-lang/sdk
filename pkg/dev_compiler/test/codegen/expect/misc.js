var misc;
(function(exports) {
  'use strict';
  // Function main: () → dynamic
  function main() {
    core.print((1).toString());
    core.print(1.0.toString());
    core.print(1.1.toString());
  }
  // Exports:
  exports.main = main;
})(misc || (misc = {}));
