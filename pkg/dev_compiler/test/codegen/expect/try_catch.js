var try_catch;
(function(exports) {
  'use strict';
  // Function foo: () → dynamic
  function foo() {
    try {
      throw "hi there";
    } catch (e$) {
      if (dart.is(e$, core.String)) {
        let e = e$;
        let t = dart.stackTrace(e);
      } else {
        let e = e$;
        let t = dart.stackTrace(e);
        throw e;
      }
    }

  }
  // Function bar: () → dynamic
  function bar() {
    try {
      throw "hi there";
    } catch (e$) {
      let e = e$;
      let t = dart.stackTrace(e);
    }

  }
  // Function main: () → dynamic
  function main() {
    foo();
    bar();
  }
  // Exports:
  exports.foo = foo;
  exports.bar = bar;
  exports.main = main;
})(try_catch || (try_catch = {}));
