dart_library.library('language/asyncstar_concat_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__asyncstar_concat_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const asyncstar_concat_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  asyncstar_concat_test.range = function(start, end) {
    return dart.asyncStar(function*(stream, start, end) {
      for (let i = core.int._check(start); dart.notNull(i) < dart.notNull(core.num._check(end)); i = dart.notNull(i) + 1) {
        if (stream.add(i)) return;
        yield;
      }
    }, dart.dynamic, start, end);
  };
  dart.fn(asyncstar_concat_test.range, dynamicAnddynamicTodynamic());
  asyncstar_concat_test.concat = function(a, b) {
    return dart.asyncStar(function*(stream, a, b) {
      if (stream.addStream(async.Stream._check(a))) return;
      yield;
      if (stream.addStream(async.Stream._check(b))) return;
      yield;
    }, dart.dynamic, a, b);
  };
  dart.fn(asyncstar_concat_test.concat, dynamicAnddynamicTodynamic());
  asyncstar_concat_test.test = function() {
    return dart.async(function*() {
      expect$.Expect.listEquals(JSArrayOfint().of([1, 2, 3, 11, 12, 13]), core.List._check(yield dart.dsend(asyncstar_concat_test.concat(asyncstar_concat_test.range(1, 4), asyncstar_concat_test.range(11, 14)), 'toList')));
    }, dart.dynamic);
  };
  dart.fn(asyncstar_concat_test.test, VoidTodynamic());
  asyncstar_concat_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(asyncstar_concat_test.test(), 'then', dart.fn(_ => {
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(asyncstar_concat_test.main, VoidTodynamic());
  // Exports:
  exports.asyncstar_concat_test = asyncstar_concat_test;
});
