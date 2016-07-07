dart_library.library('language/asyncstar_yield_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__asyncstar_yield_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const asyncstar_yield_test = Object.create(null);
  let StreamOfint = () => (StreamOfint = dart.constFn(async.Stream$(core.int)))();
  let CompleterOfbool = () => (CompleterOfbool = dart.constFn(async.Completer$(core.bool)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidToStreamOfint = () => (VoidToStreamOfint = dart.constFn(dart.definiteFunctionType(StreamOfint(), [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicToStreamOfint = () => (dynamicToStreamOfint = dart.constFn(dart.definiteFunctionType(StreamOfint(), [dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  asyncstar_yield_test.foo1 = function() {
    return dart.asyncStar(function*(stream) {
      if (stream.add(1)) return;
      yield;
      let p = (yield async.Future.value(10));
      if (stream.add(core.int._check(dart.dsend(p, '+', 10)))) return;
      yield;
    }, core.int);
  };
  dart.fn(asyncstar_yield_test.foo1, VoidToStreamOfint());
  asyncstar_yield_test.foo2 = function() {
    return dart.asyncStar(function*(stream) {
      let i = 0;
      while (true) {
        yield async.Future.delayed(new core.Duration({milliseconds: 0}), dart.fn(() => {
        }, VoidTodynamic()));
        if (i > 10) return;
        if (stream.add(i)) return;
        yield;
        i++;
      }
    }, core.int);
  };
  dart.fn(asyncstar_yield_test.foo2, VoidToStreamOfint());
  asyncstar_yield_test.foo3 = function(p) {
    return dart.asyncStar(function*(stream, p) {
      let i = 0;
      let t = false;
      if (stream.add(null)) return;
      yield;
      while (true) {
        i++;
        a:
          for (let i = 0; i < dart.notNull(core.num._check(p)); i++) {
            if (!t) {
              for (let j = 0; j < 3; j++) {
                if (stream.add(-1)) return;
                yield;
                t = true;
                break a;
              }
            }
            yield 4;
            if (stream.add(i)) return;
            yield;
          }
      }
    }, core.int, p);
  };
  dart.fn(asyncstar_yield_test.foo3, dynamicToStreamOfint());
  dart.defineLazy(asyncstar_yield_test, {
    get finalized() {
      return CompleterOfbool().new();
    },
    set finalized(_) {}
  });
  asyncstar_yield_test.foo4 = function() {
    return dart.asyncStar(function*(stream) {
      let i = 0;
      try {
        while (true) {
          if (stream.add(i)) return;
          yield;
          i++;
        }
      } finally {
        asyncstar_yield_test.finalized.complete(true);
      }
    }, core.int);
  };
  dart.fn(asyncstar_yield_test.foo4, VoidToStreamOfint());
  asyncstar_yield_test.test = function() {
    return dart.async(function*() {
      expect$.Expect.listEquals(JSArrayOfint().of([1, 20]), yield asyncstar_yield_test.foo1().toList());
      expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 2, 3]), yield asyncstar_yield_test.foo2().take(4).toList());
      expect$.Expect.listEquals(JSArrayOfint().of([null, -1, 0, 1, 2, 3, 0, 1, 2, 3]), yield asyncstar_yield_test.foo3(4).take(10).toList());
      expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]), yield asyncstar_yield_test.foo4().take(10).toList());
      expect$.Expect.isTrue(yield asyncstar_yield_test.finalized.future);
    }, dart.dynamic);
  };
  dart.fn(asyncstar_yield_test.test, VoidTodynamic());
  asyncstar_yield_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(asyncstar_yield_test.test(), 'then', dart.fn(_ => {
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(asyncstar_yield_test.main, VoidTodynamic());
  // Exports:
  exports.asyncstar_yield_test = asyncstar_yield_test;
});
