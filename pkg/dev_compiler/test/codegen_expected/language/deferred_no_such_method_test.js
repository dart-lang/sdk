dart_library.library('language/deferred_no_such_method_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__deferred_no_such_method_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const deferred_no_such_method_test = Object.create(null);
  const deferred_no_such_method_lib = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  deferred_no_such_method_test.main = function() {
    async_helper$.asyncStart();
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      expect$.Expect.equals(42, dart.dsend(new deferred_no_such_method_lib.C(), 'nonExisting'));
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_no_such_method_test.main, VoidTovoid());
  deferred_no_such_method_lib.C = class C extends core.Object {
    noSuchMethod(invocation) {
      return 42;
    }
  };
  // Exports:
  exports.deferred_no_such_method_test = deferred_no_such_method_test;
  exports.deferred_no_such_method_lib = deferred_no_such_method_lib;
});
