dart_library.library('language/deferred_only_constant_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deferred_only_constant_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deferred_only_constant_test = Object.create(null);
  const deferred_only_constant_lib = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let const$;
  deferred_only_constant_test.main = function() {
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      expect$.Expect.equals(deferred_only_constant_lib.constant, const$ || (const$ = dart.constList(["a", "b", "c"], core.String)));
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_only_constant_test.main, VoidTovoid());
  deferred_only_constant_lib.constant = dart.constList(["a", "b", "c"], core.String);
  // Exports:
  exports.deferred_only_constant_test = deferred_only_constant_test;
  exports.deferred_only_constant_lib = deferred_only_constant_lib;
});
