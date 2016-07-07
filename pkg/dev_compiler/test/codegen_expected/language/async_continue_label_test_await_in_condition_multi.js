dart_library.library('language/async_continue_label_test_await_in_condition_multi', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__async_continue_label_test_await_in_condition_multi(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const async_continue_label_test_await_in_condition_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  async_continue_label_test_await_in_condition_multi.test1 = function() {
    return dart.async(function*() {
      let r = 0;
      label:
        for (let i = 1, j = 10; i < 10 && j > dart.notNull(yield -5); j--, i = i + 1) {
          if (i < 5 || j < -5) {
            continue label;
          }
          r++;
        }
      expect$.Expect.equals(5, r);
    }, dart.dynamic);
  };
  dart.fn(async_continue_label_test_await_in_condition_multi.test1, VoidTodynamic());
  async_continue_label_test_await_in_condition_multi.test2 = function() {
    return dart.async(function*() {
      let r = 0;
      label:
        for (let i = 0; i < dart.notNull(yield 10); i = i + 1) {
          if (i < 5) {
            continue label;
          }
          r++;
        }
      expect$.Expect.equals(5, r);
    }, dart.dynamic);
  };
  dart.fn(async_continue_label_test_await_in_condition_multi.test2, VoidTodynamic());
  async_continue_label_test_await_in_condition_multi.test3 = function() {
    return dart.async(function*() {
      let r = 0, i = null, j = null;
      label:
        for (i = 0; dart.test(dart.dsend(i, '<', yield 10)); i = dart.dsend(i, '+', 1)) {
          if (dart.test(dart.dsend(i, '<', 5))) {
            continue label;
          }
          r++;
        }
      expect$.Expect.equals(5, r);
    }, dart.dynamic);
  };
  dart.fn(async_continue_label_test_await_in_condition_multi.test3, VoidTodynamic());
  async_continue_label_test_await_in_condition_multi.test4 = function() {
    return dart.async(function*() {
      let r = 0;
      label:
        for (let i = 0; i < dart.notNull(yield 10); i = i + 1) {
          if (i < 5) {
            for (let i = 0; i < 10; i++) {
              continue label;
            }
          }
          r++;
        }
      expect$.Expect.equals(5, r);
    }, dart.dynamic);
  };
  dart.fn(async_continue_label_test_await_in_condition_multi.test4, VoidTodynamic());
  async_continue_label_test_await_in_condition_multi.test = function() {
    return dart.async(function*() {
      yield async_continue_label_test_await_in_condition_multi.test1();
      yield async_continue_label_test_await_in_condition_multi.test2();
      yield async_continue_label_test_await_in_condition_multi.test3();
      yield async_continue_label_test_await_in_condition_multi.test4();
    }, dart.dynamic);
  };
  dart.fn(async_continue_label_test_await_in_condition_multi.test, VoidTodynamic());
  async_continue_label_test_await_in_condition_multi.main = function() {
    async_helper$.asyncStart();
    dart.dsend(async_continue_label_test_await_in_condition_multi.test(), 'then', dart.fn(_ => async_helper$.asyncEnd(), dynamicTovoid()));
  };
  dart.fn(async_continue_label_test_await_in_condition_multi.main, VoidTodynamic());
  // Exports:
  exports.async_continue_label_test_await_in_condition_multi = async_continue_label_test_await_in_condition_multi;
});
