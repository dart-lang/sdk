dart_library.library('language/await_for_cancel_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__await_for_cancel_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const await_for_cancel_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToStreamController = () => (VoidToStreamController = dart.constFn(dart.definiteFunctionType(async.StreamController, [])))();
  await_for_cancel_test.canceled = null;
  await_for_cancel_test.test1 = function() {
    return dart.async(function*() {
      await_for_cancel_test.canceled = false;
      try {
        let controller = await_for_cancel_test.infiniteStreamController();
        outer:
          while (true) {
            let it = async.StreamIterator.new(controller.stream);
            try {
              while (yield it.moveNext()) {
                let x = it.current;
                for (let j = 0; j < 10; j++) {
                  if (j == 5) break outer;
                }
              }
            } finally {
              yield it.cancel();
            }
          }
      } finally {
        expect$.Expect.isTrue(await_for_cancel_test.canceled);
      }
    }, dart.dynamic);
  };
  dart.fn(await_for_cancel_test.test1, VoidTodynamic());
  await_for_cancel_test.test2 = function() {
    return dart.async(function*() {
      await_for_cancel_test.canceled = false;
      try {
        let controller = await_for_cancel_test.infiniteStreamController();
        let first = true;
        outer:
          while (true) {
            if (first) {
              first = false;
            } else {
              break;
            }
            let it = async.StreamIterator.new(controller.stream);
            try {
              while (yield it.moveNext()) {
                let x = it.current;
                for (let j = 0; j < 10; j++) {
                  if (j == 5) continue outer;
                }
              }
            } finally {
              yield it.cancel();
            }
          }
      } finally {
        expect$.Expect.isTrue(await_for_cancel_test.canceled);
      }
    }, dart.dynamic);
  };
  dart.fn(await_for_cancel_test.test2, VoidTodynamic());
  await_for_cancel_test.test = function() {
    return dart.async(function*() {
      yield await_for_cancel_test.test1();
      yield await_for_cancel_test.test2();
    }, dart.dynamic);
  };
  dart.fn(await_for_cancel_test.test, VoidTodynamic());
  await_for_cancel_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(await_for_cancel_test.test(), 'then', dart.fn(_ => {
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(await_for_cancel_test.main, VoidTodynamic());
  await_for_cancel_test.infiniteStreamController = function() {
    let controller = null;
    let timer = null;
    let counter = 0;
    function tick() {
      if (dart.test(controller.isPaused)) {
        return;
      }
      if (dart.test(await_for_cancel_test.canceled)) {
        return;
      }
      counter++;
      controller.add(counter);
      async.Timer.run(tick);
    }
    dart.fn(tick, VoidTovoid());
    function startTimer() {
      async.Timer.run(tick);
    }
    dart.fn(startTimer, VoidTovoid());
    controller = async.StreamController.new({onListen: startTimer, onResume: startTimer, onCancel: dart.fn(() => {
        await_for_cancel_test.canceled = true;
      }, VoidTodynamic())});
    return controller;
  };
  dart.fn(await_for_cancel_test.infiniteStreamController, VoidToStreamController());
  // Exports:
  exports.await_for_cancel_test = await_for_cancel_test;
});
