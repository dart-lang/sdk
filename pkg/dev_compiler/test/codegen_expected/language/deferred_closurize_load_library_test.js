dart_library.library('language/deferred_closurize_load_library_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__deferred_closurize_load_library_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const deferred_closurize_load_library_test = Object.create(null);
  const deferred_closurize_load_library_lib = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  deferred_closurize_load_library_test.main = function() {
    let x = loadLibrary;
    async_helper$.asyncStart();
    x().then(dart.dynamic)(dart.fn(_ => {
      expect$.Expect.isTrue(deferred_closurize_load_library_lib.trueVar);
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_closurize_load_library_test.main, VoidTovoid());
  deferred_closurize_load_library_lib.trueVar = true;
  // Exports:
  exports.deferred_closurize_load_library_test = deferred_closurize_load_library_test;
  exports.deferred_closurize_load_library_lib = deferred_closurize_load_library_lib;
});
