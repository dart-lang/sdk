dart_library.library('language/deferred_shadow_load_library_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__deferred_shadow_load_library_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const deferred_shadow_load_library_test = Object.create(null);
  const deferred_shadow_load_library_lib = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deferred_shadow_load_library_test.main = function() {
    let x = loadLibrary();
    expect$.Expect.isTrue(async.Future.is(x));
    async_helper$.asyncStart();
    x.then(dart.dynamic)(dart.fn(_ => {
      expect$.Expect.isTrue(deferred_shadow_load_library_lib.trueVar);
      expect$.Expect.isTrue(async.Future.is(loadLibrary()));
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_shadow_load_library_test.main, VoidTovoid());
  deferred_shadow_load_library_lib.loadLibrary = function() {
    return 42;
  };
  dart.fn(deferred_shadow_load_library_lib.loadLibrary, VoidTodynamic());
  deferred_shadow_load_library_lib.trueVar = true;
  // Exports:
  exports.deferred_shadow_load_library_test = deferred_shadow_load_library_test;
  exports.deferred_shadow_load_library_lib = deferred_shadow_load_library_lib;
});
