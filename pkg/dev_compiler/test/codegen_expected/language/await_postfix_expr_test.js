dart_library.library('language/await_postfix_expr_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__await_postfix_expr_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const await_postfix_expr_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  await_postfix_expr_test.post0 = function(a) {
    return dart.async(function*(a) {
      return yield (() => {
        let x = a;
        a = dart.dsend(x, '+', 1);
        return x;
      })();
    }, dart.dynamic, a);
  };
  dart.fn(await_postfix_expr_test.post0, dynamicTodynamic());
  await_postfix_expr_test.post1 = function(a) {
    return dart.async(function*(a) {
      return dart.dsend(yield (() => {
        let x = a;
        a = dart.dsend(x, '+', 1);
        return x;
      })(), '+', yield (() => {
        let x = a;
        a = dart.dsend(x, '+', 1);
        return x;
      })());
    }, dart.dynamic, a);
  };
  dart.fn(await_postfix_expr_test.post1, dynamicTodynamic());
  await_postfix_expr_test.pref0 = function(a) {
    return dart.async(function*(a) {
      return yield (a = dart.dsend(a, '+', 1));
    }, dart.dynamic, a);
  };
  dart.fn(await_postfix_expr_test.pref0, dynamicTodynamic());
  await_postfix_expr_test.pref1 = function(a) {
    return dart.async(function*(a) {
      return dart.dsend(yield (a = dart.dsend(a, '+', 1)), '+', yield (a = dart.dsend(a, '+', 1)));
    }, dart.dynamic, a);
  };
  dart.fn(await_postfix_expr_test.pref1, dynamicTodynamic());
  await_postfix_expr_test.sum = function(a) {
    return dart.async(function*(a) {
      let s = 0;
      for (let i = 0; i < dart.notNull(core.num._check(dart.dload(a, 'length')));) {
        s = dart.notNull(s) + dart.notNull(core.int._check(dart.dindex(a, yield i++)));
      }
      return s;
    }, dart.dynamic, a);
  };
  dart.fn(await_postfix_expr_test.sum, dynamicTodynamic());
  await_postfix_expr_test.sum2 = function(n) {
    return dart.async(function*(n) {
      let i = null, s = 0;
      for (i = 1; dart.notNull(i) <= dart.notNull(core.num._check(n)); yield (() => {
        let x = i;
        i = dart.notNull(x) + 1;
        return x;
      })()) {
        let j = (yield i);
        s = dart.notNull(s) + dart.notNull(j);
      }
      return s;
    }, dart.dynamic, n);
  };
  dart.fn(await_postfix_expr_test.sum2, dynamicTodynamic());
  await_postfix_expr_test.test = function() {
    return dart.async(function*() {
      expect$.Expect.equals(10, yield await_postfix_expr_test.post0(10));
      expect$.Expect.equals(21, yield await_postfix_expr_test.post1(10));
      expect$.Expect.equals(11, yield await_postfix_expr_test.pref0(10));
      expect$.Expect.equals(23, yield await_postfix_expr_test.pref1(10));
      expect$.Expect.equals(10, yield await_postfix_expr_test.sum(JSArrayOfint().of([1, 2, 3, 4])));
      expect$.Expect.equals(10, yield await_postfix_expr_test.sum2(4));
    }, dart.dynamic);
  };
  dart.fn(await_postfix_expr_test.test, VoidTodynamic());
  await_postfix_expr_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(await_postfix_expr_test.test(), 'then', dart.fn(_ => {
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(await_postfix_expr_test.main, VoidTodynamic());
  // Exports:
  exports.await_postfix_expr_test = await_postfix_expr_test;
});
