dart_library.library('language/await_nonfuture_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__await_nonfuture_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const await_nonfuture_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  await_nonfuture_test.X = 0;
  await_nonfuture_test.foo = function() {
    return dart.async(function*() {
      expect$.Expect.equals(await_nonfuture_test.X, 10);
      return yield 5;
    }, dart.dynamic);
  };
  dart.fn(await_nonfuture_test.foo, VoidTodynamic());
  await_nonfuture_test.main = function() {
    let f = await_nonfuture_test.foo();
    dart.dsend(f, 'then', dart.fn(res => core.print(dart.str`f completed with ${res}`), dynamicTovoid()));
    await_nonfuture_test.X = 10;
  };
  dart.fn(await_nonfuture_test.main, VoidTodynamic());
  // Exports:
  exports.await_nonfuture_test = await_nonfuture_test;
});
