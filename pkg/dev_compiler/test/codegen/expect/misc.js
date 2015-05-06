var misc = dart.defineLibrary(misc, {});
var core = dart.import(core);
(function(exports, core) {
  'use strict';
  // Function main: () → dynamic
  function main() {
    core.print(dart.toString(1));
    core.print(dart.toString(1.0));
    core.print(dart.toString(1.1));
  }
  // Exports:
  exports.main = main;
})(misc, core);
