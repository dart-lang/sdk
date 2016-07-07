dart_library.library('language/async_star_regression_23116_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__async_star_regression_23116_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const async_star_regression_23116_test = Object.create(null);
  let StreamOfint = () => (StreamOfint = dart.constFn(async.Stream$(core.int)))();
  let CompleterAndFutureToStreamOfint = () => (CompleterAndFutureToStreamOfint = dart.constFn(dart.definiteFunctionType(StreamOfint(), [async.Completer, async.Future])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  async_star_regression_23116_test.foo = function(completer, future) {
    return dart.asyncStar(function*(stream, completer, future) {
      completer.complete(100);
      let x = core.int._check(yield future);
      expect$.Expect.equals(42, x);
    }, core.int, completer, future);
  };
  dart.fn(async_star_regression_23116_test.foo, CompleterAndFutureToStreamOfint());
  async_star_regression_23116_test.test = function() {
    return dart.async(function*() {
      let completer1 = async.Completer.new();
      let completer2 = async.Completer.new();
      let s = async_star_regression_23116_test.foo(completer1, completer2.future).listen(dart.fn(v => null, intTovoid()));
      yield completer1.future;
      s.pause();
      s.resume();
      completer2.complete(42);
    }, dart.dynamic);
  };
  dart.fn(async_star_regression_23116_test.test, VoidTodynamic());
  async_star_regression_23116_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(async_star_regression_23116_test.test(), 'then', dart.fn(_ => async_helper$.asyncEnd(), dynamicTovoid()));
  };
  dart.fn(async_star_regression_23116_test.main, VoidTodynamic());
  // Exports:
  exports.async_star_regression_23116_test = async_star_regression_23116_test;
});
