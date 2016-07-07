dart_library.library('language/deferred_constant_list_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__deferred_constant_list_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const deferred_constant_list_test = Object.create(null);
  const deferred_constant_list_lib = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  deferred_constant_list_test.main = function() {
    async_helper$.asyncStart();
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      expect$.Expect.equals("[1, 2]", dart.toString(deferred_constant_list_lib.finalConstList));
      expect$.Expect.equals("[3, 4]", dart.toString(deferred_constant_list_lib.nonFinalConstList));
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_constant_list_test.main, VoidTovoid());
  deferred_constant_list_lib.finalConstList = dart.constList([1, 2], core.int);
  deferred_constant_list_lib.nonFinalConstList = dart.constList([3, 4], core.int);
  // Exports:
  exports.deferred_constant_list_test = deferred_constant_list_test;
  exports.deferred_constant_list_lib = deferred_constant_list_lib;
});
