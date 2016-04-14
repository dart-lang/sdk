dart_library.library('destructuring', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const destructuring = Object.create(null);
  destructuring.f = function(a, b, c = 1) {
    destructuring.f(a, b, c);
  };
  dart.fn(destructuring.f, dart.dynamic, [core.int, dart.dynamic], [dart.dynamic]);
  destructuring.f_sync = function(a, b, c) {
    return dart.syncStar(function*(a, b, c = 1) {
    }, dart.dynamic, a, b, c);
  };
  dart.fn(destructuring.f_sync, dart.dynamic, [core.int, dart.dynamic], [dart.dynamic]);
  destructuring.f_async = function(a, b, c) {
    return dart.asyncStar(function*(stream, a, b, c = 1) {
    }, dart.dynamic, a, b, c);
  };
  dart.fn(destructuring.f_async, dart.dynamic, [core.int, dart.dynamic], [dart.dynamic]);
  destructuring.g = function(a, b, {c = 1} = {}) {
    destructuring.f(a, b, c);
  };
  dart.fn(destructuring.g, dart.dynamic, [core.int, dart.dynamic], {c: dart.dynamic});
  destructuring.g_sync = function(a, b, opts) {
    return dart.syncStar(function*(a, b, {c = 1} = {}) {
    }, dart.dynamic, a, b, opts);
  };
  dart.fn(destructuring.g_sync, dart.dynamic, [core.int, dart.dynamic], {c: dart.dynamic});
  destructuring.g_async = function(a, b, opts) {
    return dart.asyncStar(function*(stream, a, b, {c = 1} = {}) {
    }, dart.dynamic, a, b, opts);
  };
  dart.fn(destructuring.g_async, dart.dynamic, [core.int, dart.dynamic], {c: dart.dynamic});
  destructuring.r = function(a, ...others) {
    destructuring.r(a, ...others);
  };
  dart.fn(destructuring.r, dart.dynamic, [core.int, dart.dynamic]);
  destructuring.r_sync = function(a, ...others) {
    return dart.syncStar(function*(a, ...others) {
    }, dart.dynamic, a, ...others);
  };
  dart.fn(destructuring.r_sync, dart.dynamic, [core.int, dart.dynamic]);
  destructuring.r_async = function(a, ...others) {
    return dart.asyncStar(function*(stream, a, ...others) {
    }, dart.dynamic, a, ...others);
  };
  dart.fn(destructuring.r_async, dart.dynamic, [core.int, dart.dynamic]);
  destructuring.invalid_names1 = function(let$, func, arguments$) {
    destructuring.f(let$, func, arguments$);
  };
  dart.fn(destructuring.invalid_names1, dart.dynamic, [core.int, dart.dynamic, dart.dynamic]);
  destructuring.invalid_names2 = function(let$ = null, func = 1, arguments$ = null) {
    destructuring.f(let$, func, arguments$);
  };
  dart.fn(destructuring.invalid_names2, dart.dynamic, [], [core.int, dart.dynamic, dart.dynamic]);
  destructuring.invalid_names3 = function({["let"]: let$ = null, ["function"]: func = null, ["arguments"]: arguments$ = 2} = {}) {
    destructuring.f(let$, func, arguments$);
  };
  dart.fn(destructuring.invalid_names3, dart.dynamic, [], {let: core.int, function: dart.dynamic, arguments: dart.dynamic});
  destructuring.names_clashing_with_object_props = function({constructor = null, valueOf = null, hasOwnProperty = 2} = Object.create(null)) {
    destructuring.f(constructor, valueOf, hasOwnProperty);
  };
  dart.fn(destructuring.names_clashing_with_object_props, dart.dynamic, [], {constructor: core.int, valueOf: dart.dynamic, hasOwnProperty: dart.dynamic});
  // Exports:
  exports.destructuring = destructuring;
});
