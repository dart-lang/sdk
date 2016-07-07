dart_library.library('language/asyncstar_yieldstar_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__asyncstar_yieldstar_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const asyncstar_yieldstar_test = Object.create(null);
  let StreamOfint = () => (StreamOfint = dart.constFn(async.Stream$(core.int)))();
  let CompleterOfbool = () => (CompleterOfbool = dart.constFn(async.Completer$(core.bool)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let dynamicToStreamOfint = () => (dynamicToStreamOfint = dart.constFn(dart.definiteFunctionType(StreamOfint(), [dart.dynamic])))();
  let CompleterOfboolToStream = () => (CompleterOfboolToStream = dart.constFn(dart.definiteFunctionType(async.Stream, [CompleterOfbool()])))();
  let StreamTodynamic = () => (StreamTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [async.Stream])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  asyncstar_yieldstar_test.subStream = function(p) {
    return dart.asyncStar(function*(stream, p) {
      if (stream.add(core.int._check(p))) return;
      yield;
      if (stream.add(core.int._check(dart.dsend(p, '+', 1)))) return;
      yield;
    }, core.int, p);
  };
  dart.fn(asyncstar_yieldstar_test.subStream, dynamicToStreamOfint());
  asyncstar_yieldstar_test.foo = function(finalized) {
    return dart.asyncStar(function*(stream, finalized) {
      let i = 0;
      try {
        while (true) {
          if (stream.add("outer")) return;
          yield;
          if (stream.addStream(asyncstar_yieldstar_test.subStream(i))) return;
          yield;
          i++;
        }
      } finally {
        expect$.Expect.isTrue(i < 10);
        finalized.complete(true);
      }
    }, dart.dynamic, finalized);
  };
  dart.fn(asyncstar_yieldstar_test.foo, CompleterOfboolToStream());
  asyncstar_yieldstar_test.foo2 = function(subStream) {
    return dart.asyncStar(function*(stream, subStream) {
      if (stream.addStream(subStream)) return;
      yield;
    }, dart.dynamic, subStream);
  };
  dart.fn(asyncstar_yieldstar_test.foo2, StreamTodynamic());
  asyncstar_yieldstar_test.test = function() {
    return dart.async(function*() {
      expect$.Expect.listEquals(JSArrayOfint().of([0, 1]), yield asyncstar_yieldstar_test.subStream(0).toList());
      let finalized = CompleterOfbool().new();
      expect$.Expect.listEquals(JSArrayOfObject().of(["outer", 0, 1, "outer", 1, 2, "outer", 2]), yield asyncstar_yieldstar_test.foo(finalized).take(8).toList());
      expect$.Expect.isTrue(yield finalized.future);
      finalized = CompleterOfbool().new();
      expect$.Expect.listEquals(JSArrayOfObject().of(["outer", 0, 1, "outer", 1, 2, "outer"]), yield asyncstar_yieldstar_test.foo(finalized).take(7).toList());
      expect$.Expect.isTrue(yield finalized.future);
      finalized = CompleterOfbool().new();
      let pausedCompleter = CompleterOfbool().new();
      let resumedCompleter = CompleterOfbool().new();
      let canceledCompleter = CompleterOfbool().new();
      let controller = null;
      let i = 0;
      function addNext() {
        if (i >= 10) return;
        controller.add(i);
        i++;
        if (!dart.test(controller.isPaused)) {
          async.scheduleMicrotask(addNext);
        }
      }
      dart.fn(addNext, VoidTodynamic());
      controller = async.StreamController.new({onListen: dart.fn(() => {
          async.scheduleMicrotask(addNext);
        }, VoidTovoid()), onPause: dart.fn(() => {
          pausedCompleter.complete(true);
        }, VoidTovoid()), onResume: dart.fn(() => {
          resumedCompleter.complete(true);
          async.scheduleMicrotask(addNext);
        }, VoidTovoid()), onCancel: dart.fn(() => {
          canceledCompleter.complete(true);
        }, VoidTodynamic())});
      let subscription = null;
      subscription = async.StreamSubscription._check(dart.dsend(asyncstar_yieldstar_test.foo2(controller.stream), 'listen', dart.fn(event => {
        if (dart.equals(event, 2)) {
          subscription.pause();
          async.scheduleMicrotask(dart.fn(() => {
            subscription.resume();
          }, VoidTovoid()));
        }
        if (dart.equals(event, 5)) {
          subscription.cancel();
        }
      }, dynamicTodynamic())));
      expect$.Expect.isTrue(yield pausedCompleter.future);
      expect$.Expect.isTrue(yield resumedCompleter.future);
      expect$.Expect.isTrue(yield canceledCompleter.future);
    }, dart.dynamic);
  };
  dart.fn(asyncstar_yieldstar_test.test, VoidTodynamic());
  asyncstar_yieldstar_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(asyncstar_yieldstar_test.test(), 'then', dart.fn(_ => {
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(asyncstar_yieldstar_test.main, VoidTodynamic());
  // Exports:
  exports.asyncstar_yieldstar_test = asyncstar_yieldstar_test;
});
