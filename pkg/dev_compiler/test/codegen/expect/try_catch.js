dart_library.library('try_catch', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  function foo() {
    try {
      dart.throw("hi there");
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
      dart.throw("hi there");
    } catch (e$) {
      let e = e$;
      let t = dart.stackTrace(e);
    }

  }
  dart.fn(bar);
  function baz() {
    try {
      dart.throw("finally only");
    } finally {
      return true;
    }
  }
  dart.fn(baz);
  function qux() {
    try {
      dart.throw("on only");
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
      dart.throw("on without exception parameter");
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
});
