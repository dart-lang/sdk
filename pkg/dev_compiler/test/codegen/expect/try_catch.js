var try_catch;
(function(exports) {
  'use strict';
  // Function main: () → dynamic
  function main() {
    try {
      throw "hi there";
    } catch ($e) {
      if (dart.is($e, core.String)) {
        let e = $e;
        let t = dart.stackTrace(e);
      }
      let e = $e;
      let t = dart.stackTrace(e);
      throw e;
    }

  }
  // Exports:
  exports.main = main;
})(try_catch || (try_catch = {}));
