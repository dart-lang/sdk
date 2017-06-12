define(['dart_sdk'], function(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const destructuring = Object.create(null);
  const src__varargs = Object.create(null);
  let intAnddynamic__Todynamic = () => (intAnddynamic__Todynamic = dart.constFn(dart.fnType(dart.dynamic, [core.int, dart.dynamic], [dart.dynamic])))();
  let intAnddynamic__Todynamic$ = () => (intAnddynamic__Todynamic$ = dart.constFn(dart.fnType(dart.dynamic, [core.int, dart.dynamic], {c: dart.dynamic})))();
  let intAnddynamicTodynamic = () => (intAnddynamicTodynamic = dart.constFn(dart.fnType(dart.dynamic, [core.int, dart.dynamic])))();
  let intAnddynamicAnddynamicTodynamic = () => (intAnddynamicAnddynamicTodynamic = dart.constFn(dart.fnType(dart.dynamic, [core.int, dart.dynamic, dart.dynamic])))();
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.fnType(dart.dynamic, [], [core.int, dart.dynamic, dart.dynamic])))();
  let __Todynamic$ = () => (__Todynamic$ = dart.constFn(dart.fnType(dart.dynamic, [], {let: core.int, function: dart.dynamic, arguments: dart.dynamic})))();
  let __Todynamic$0 = () => (__Todynamic$0 = dart.constFn(dart.fnType(dart.dynamic, [], {constructor: core.int, valueOf: dart.dynamic, hasOwnProperty: dart.dynamic})))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.fnType(dart.dynamic, [dart.dynamic])))();
  destructuring.f = function(a, b, c = 1) {
    destructuring.f(a, b, c);
  };
  dart.fn(destructuring.f, intAnddynamic__Todynamic());
  destructuring.f_sync = function(a, b, c) {
    return dart.syncStar(function*(a, b, c = 1) {
    }, dart.dynamic, a, b, c);
  };
  dart.fn(destructuring.f_sync, intAnddynamic__Todynamic());
  destructuring.f_async = function(a, b, c) {
    return dart.asyncStar(function*(stream, a, b, c = 1) {
    }, dart.dynamic, a, b, c);
  };
  dart.fn(destructuring.f_async, intAnddynamic__Todynamic());
  destructuring.g = function(a, b, {c = 1} = {}) {
    destructuring.f(a, b, c);
  };
  dart.fn(destructuring.g, intAnddynamic__Todynamic$());
  destructuring.g_sync = function(a, b, opts) {
    return dart.syncStar(function*(a, b, {c = 1} = {}) {
    }, dart.dynamic, a, b, opts);
  };
  dart.fn(destructuring.g_sync, intAnddynamic__Todynamic$());
  destructuring.g_async = function(a, b, opts) {
    return dart.asyncStar(function*(stream, a, b, {c = 1} = {}) {
    }, dart.dynamic, a, b, opts);
  };
  dart.fn(destructuring.g_async, intAnddynamic__Todynamic$());
  destructuring.r = function(a, ...others) {
    destructuring.r(a, ...others);
  };
  dart.fn(destructuring.r, intAnddynamicTodynamic());
  destructuring.r_sync = function(a, ...others) {
    return dart.syncStar(function*(a, ...others) {
    }, dart.dynamic, a, ...others);
  };
  dart.fn(destructuring.r_sync, intAnddynamicTodynamic());
  destructuring.r_async = function(a, ...others) {
    return dart.asyncStar(function*(stream, a, ...others) {
    }, dart.dynamic, a, ...others);
  };
  dart.fn(destructuring.r_async, intAnddynamicTodynamic());
  destructuring.invalid_names1 = function(let$, func, arguments$) {
    destructuring.f(let$, func, arguments$);
  };
  dart.fn(destructuring.invalid_names1, intAnddynamicAnddynamicTodynamic());
  destructuring.invalid_names2 = function(let$ = null, func = 1, arguments$ = null) {
    destructuring.f(let$, func, arguments$);
  };
  dart.fn(destructuring.invalid_names2, __Todynamic());
  destructuring.invalid_names3 = function({["let"]: let$ = null, ["function"]: func = null, ["arguments"]: arguments$ = 2} = {}) {
    destructuring.f(let$, func, arguments$);
  };
  dart.fn(destructuring.invalid_names3, __Todynamic$());
  destructuring.names_clashing_with_object_props = function({constructor = null, valueOf = null, hasOwnProperty = 2} = Object.create(null)) {
    destructuring.f(constructor, valueOf, hasOwnProperty);
  };
  dart.fn(destructuring.names_clashing_with_object_props, __Todynamic$0());
  src__varargs._Rest = class _Rest extends core.Object {
    new() {
    }
  };
  dart.defineLazy(src__varargs, {
    get rest() {
      return dart.const(new src__varargs._Rest());
    }
  });
  src__varargs.spread = function(args) {
    dart.throw(new core.StateError('The spread function cannot be called, ' + 'it should be compiled away.'));
  };
  dart.fn(src__varargs.spread, dynamicTodynamic());
  dart.trackLibraries("destructuring", {
    "destructuring.dart": destructuring,
    "package:js/src/varargs.dart": src__varargs
  }, null);
  // Exports:
  return {
    destructuring: destructuring,
    src__varargs: src__varargs
  };
});
