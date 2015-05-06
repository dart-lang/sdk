var try_catch = dart.defineLibrary(try_catch, {});
var core = dart.import(core);
(function(exports, core) {
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
  // Function baz: () → dynamic
  function baz() {
    try {
      throw "finally only";
    } finally {
      return true;
    }
  }
  // Function qux: () → dynamic
  function qux() {
    try {
      throw "on only";
    } catch (e) {
      if (dart.is(e, core.String)) {
        let t = dart.stackTrace(e);
        throw e;
      } else
        throw e;
    }

  }
  // Function wub: () → dynamic
  function wub() {
    try {
      throw "on without exception parameter";
    } catch (e$) {
      if (dart.is(e$, core.String)) {
      } else
        throw e$;
    }

  }
  // Function main: () → dynamic
  function main() {
    foo();
    bar();
    baz();
    qux();
    wub();
  }
  // Exports:
  exports.foo = foo;
  exports.bar = bar;
  exports.baz = baz;
  exports.qux = qux;
  exports.wub = wub;
  exports.main = main;
})(try_catch, core);
