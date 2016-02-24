dart_library.library('destructuring', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  function f(a, b, c = 1) {
    f(a, b, c);
  }
  dart.fn(f, dart.dynamic, [core.int, dart.dynamic], [dart.dynamic]);
  function f_sync(a, b, c) {
    return dart.syncStar(function*(a, b, c = 1) {
    }, dart.dynamic, a, b, c);
  }
  dart.fn(f_sync, dart.dynamic, [core.int, dart.dynamic], [dart.dynamic]);
  function f_async(a, b, c) {
    return dart.asyncStar(function*(stream, a, b, c = 1) {
    }, dart.dynamic, a, b, c);
  }
  dart.fn(f_async, dart.dynamic, [core.int, dart.dynamic], [dart.dynamic]);
  function g(a, b, {c = 1} = {}) {
    f(a, b, c);
  }
  dart.fn(g, dart.dynamic, [core.int, dart.dynamic], {c: dart.dynamic});
  function g_sync(a, b, opts) {
    return dart.syncStar(function*(a, b, {c = 1} = {}) {
    }, dart.dynamic, a, b, opts);
  }
  dart.fn(g_sync, dart.dynamic, [core.int, dart.dynamic], {c: dart.dynamic});
  function g_async(a, b, opts) {
    return dart.asyncStar(function*(stream, a, b, {c = 1} = {}) {
    }, dart.dynamic, a, b, opts);
  }
  dart.fn(g_async, dart.dynamic, [core.int, dart.dynamic], {c: dart.dynamic});
  function r(a, ...others) {
    r(a, ...others);
  }
  dart.fn(r, dart.dynamic, [core.int, dart.dynamic]);
  function r_sync(a, ...others) {
    return dart.syncStar(function*(a, ...others) {
    }, dart.dynamic, a, ...others);
  }
  dart.fn(r_sync, dart.dynamic, [core.int, dart.dynamic]);
  function r_async(a, ...others) {
    return dart.asyncStar(function*(stream, a, ...others) {
    }, dart.dynamic, a, ...others);
  }
  dart.fn(r_async, dart.dynamic, [core.int, dart.dynamic]);
  function invalid_names1(let$, func, arguments$) {
    f(let$, func, arguments$);
  }
  dart.fn(invalid_names1, dart.dynamic, [core.int, dart.dynamic, dart.dynamic]);
  function invalid_names2(let$ = null, func = 1, arguments$ = null) {
    f(let$, func, arguments$);
  }
  dart.fn(invalid_names2, dart.dynamic, [], [core.int, dart.dynamic, dart.dynamic]);
  function invalid_names3({["let"]: let$ = null, ["function"]: func = null, ["arguments"]: arguments$ = 2} = {}) {
    f(let$, func, arguments$);
  }
  dart.fn(invalid_names3, dart.dynamic, [], {let: core.int, function: dart.dynamic, arguments: dart.dynamic});
  function names_clashing_with_object_props({constructor = null, valueOf = null, hasOwnProperty = 2} = Object.create(null)) {
    f(constructor, valueOf, hasOwnProperty);
  }
  dart.fn(names_clashing_with_object_props, dart.dynamic, [], {constructor: core.int, valueOf: dart.dynamic, hasOwnProperty: dart.dynamic});
  // Exports:
  exports.f = f;
  exports.f_sync = f_sync;
  exports.f_async = f_async;
  exports.g = g;
  exports.g_sync = g_sync;
  exports.g_async = g_async;
  exports.r = r;
  exports.r_sync = r_sync;
  exports.r_async = r_async;
  exports.invalid_names1 = invalid_names1;
  exports.invalid_names2 = invalid_names2;
  exports.invalid_names3 = invalid_names3;
  exports.names_clashing_with_object_props = names_clashing_with_object_props;
});
