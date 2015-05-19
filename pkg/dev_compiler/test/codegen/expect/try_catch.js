var try_catch = dart.defineLibrary(try_catch, {});
var core = dart.import(core);
(function(exports, core) {
  'use strict';
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
  dart.fn(foo);
  function bar() {
    try {
      throw "hi there";
    } catch (e$) {
      let e = e$;
      let t = dart.stackTrace(e);
    }

  }
  dart.fn(bar);
  function baz() {
    try {
      throw "finally only";
    } finally {
      return true;
    }
  }
  dart.fn(baz);
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
  dart.fn(qux);
  function wub() {
    try {
      throw "on without exception parameter";
    } catch (e) {
      if (dart.is(e, core.String)) {
      } else
        throw e;
    }

  }
  dart.fn(wub);
  function main() {
    foo();
    bar();
    baz();
    qux();
    wub();
  }
  dart.fn(main);
  // Exports:
  exports.foo = foo;
  exports.bar = bar;
  exports.baz = baz;
  exports.qux = qux;
  exports.wub = wub;
  exports.main = main;
})(try_catch, core);
