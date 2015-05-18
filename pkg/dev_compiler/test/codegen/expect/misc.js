var misc = dart.defineLibrary(misc, {});
var core = dart.import(core);
(function(exports, core) {
  'use strict';
  class _Uninitialized extends core.Object {
    _Uninitialized() {
    }
  }
  let UNINITIALIZED = dart.const(new _Uninitialized());
  let Generic$ = dart.generic(function(T) {
    class Generic extends core.Object {
      get type() {
        return Generic$();
      }
    }
    return Generic;
  });
  let Generic = Generic$();
  // Function main: () → dynamic
  function main() {
    core.print(dart.toString(1));
    core.print(dart.toString(1.0));
    core.print(dart.toString(1.1));
    let x = 42;
    core.print(dart.equals(x, dart.dynamic));
    core.print(dart.equals(x, Generic));
    core.print(new (Generic$(core.int))().type);
  }
  // Exports:
  exports.UNINITIALIZED = UNINITIALIZED;
  exports.Generic$ = Generic$;
  exports.Generic = Generic;
  exports.main = main;
})(misc, core);
