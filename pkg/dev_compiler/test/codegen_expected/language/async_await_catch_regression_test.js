dart_library.library('language/async_await_catch_regression_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__async_await_catch_regression_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const async_await_catch_regression_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  async_await_catch_regression_test.foo = function() {
    return dart.async(function*() {
      dart.throw(42);
    }, dart.dynamic);
  };
  dart.fn(async_await_catch_regression_test.foo, VoidTodynamic());
  async_await_catch_regression_test.test = function() {
    return dart.async(function*() {
      let exception = null;
      try {
        yield async_await_catch_regression_test.foo();
      } catch (e) {
        core.print(yield e);
        yield exception = (yield e);
      }

      expect$.Expect.equals(42, exception);
    }, dart.dynamic);
  };
  dart.fn(async_await_catch_regression_test.test, VoidTodynamic());
  async_await_catch_regression_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(async_await_catch_regression_test.test(), 'then', dart.fn(_ => async_helper$.asyncEnd(), dynamicTovoid()));
  };
  dart.fn(async_await_catch_regression_test.main, VoidTodynamic());
  // Exports:
  exports.async_await_catch_regression_test = async_await_catch_regression_test;
});
