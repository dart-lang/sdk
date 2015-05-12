var misc = dart.defineLibrary(misc, {});
var core = dart.import(core);
(function(exports, core) {
  'use strict';
  class _Uninitialized extends core.Object {
    _Uninitialized() {
    }
  }
  let UNINITIALIZED = dart.const(new _Uninitialized());
  // Function main: () → dynamic
  function main() {
    core.print(dart.toString(1));
    core.print(dart.toString(1.0));
    core.print(dart.toString(1.1));
  }
  // Exports:
  exports.UNINITIALIZED = UNINITIALIZED;
  exports.main = main;
})(misc, core);
