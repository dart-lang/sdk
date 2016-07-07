dart_library.library('language/generic_async_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_async_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_async_test = Object.create(null);
  let TToFutureOfT = () => (TToFutureOfT = dart.constFn(dart.definiteFunctionType(T => [async.Future$(T), [T]])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_async_test.foo = function(T) {
    return x => {
      return dart.async(function*(x) {
        return x;
      }, T, x);
    };
  };
  dart.fn(generic_async_test.foo, TToFutureOfT());
  generic_async_test.main = function() {
    return dart.async(function*() {
      expect$.Expect.equals(1, yield generic_async_test.foo(core.int)(1));
    }, dart.dynamic);
  };
  dart.fn(generic_async_test.main, VoidTodynamic());
  // Exports:
  exports.generic_async_test = generic_async_test;
});
