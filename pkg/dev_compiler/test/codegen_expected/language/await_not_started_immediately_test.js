dart_library.library('language/await_not_started_immediately_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__await_not_started_immediately_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const await_not_started_immediately_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  await_not_started_immediately_test.x = 0;
  await_not_started_immediately_test.foo = function() {
    return dart.async(function*() {
      await_not_started_immediately_test.x = dart.notNull(await_not_started_immediately_test.x) + 1;
      yield 1;
      await_not_started_immediately_test.x = dart.notNull(await_not_started_immediately_test.x) + 1;
    }, dart.dynamic);
  };
  dart.fn(await_not_started_immediately_test.foo, VoidTodynamic());
  await_not_started_immediately_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(dart.dsend(await_not_started_immediately_test.foo(), 'then', dart.fn(_ => expect$.Expect.equals(2, await_not_started_immediately_test.x), dynamicTovoid())), 'whenComplete', async_helper$.asyncEnd);
    expect$.Expect.equals(0, await_not_started_immediately_test.x);
  };
  dart.fn(await_not_started_immediately_test.main, VoidTovoid());
  // Exports:
  exports.await_not_started_immediately_test = await_not_started_immediately_test;
});
