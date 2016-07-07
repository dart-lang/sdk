dart_library.library('language/await_for_use_local_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__await_for_use_local_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const await_for_use_local_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  await_for_use_local_test.sumStream = function(s) {
    return dart.async(function*(s) {
      let accum = 0;
      let it = async.StreamIterator.new(async.Stream._check(s));
      try {
        while (yield it.moveNext()) {
          let v = it.current;
          accum = dart.notNull(accum) + dart.notNull(core.int._check(v));
        }
      } finally {
        yield it.cancel();
      }
      return accum;
    }, dart.dynamic, s);
  };
  dart.fn(await_for_use_local_test.sumStream, dynamicTodynamic());
  await_for_use_local_test.test = function() {
    return dart.async(function*() {
      let countStreamController = null;
      let i = 0;
      function tick() {
        if (i < 10) {
          dart.dsend(countStreamController, 'add', i);
          i++;
          async.scheduleMicrotask(tick);
        } else {
          dart.dsend(countStreamController, 'close');
        }
      }
      dart.fn(tick, VoidTovoid());
      countStreamController = async.StreamController.new({onListen: dart.fn(() => {
          async.scheduleMicrotask(tick);
        }, VoidTovoid())});
      expect$.Expect.equals(45, yield await_for_use_local_test.sumStream(dart.dload(countStreamController, 'stream')));
    }, dart.dynamic);
  };
  dart.fn(await_for_use_local_test.test, VoidTodynamic());
  await_for_use_local_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(await_for_use_local_test.test(), 'then', dart.fn(_ => async_helper$.asyncEnd(), dynamicTovoid()));
  };
  dart.fn(await_for_use_local_test.main, VoidTovoid());
  // Exports:
  exports.await_for_use_local_test = await_for_use_local_test;
});
