dart_library.library('language/async_switch_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__async_switch_test_none_multi(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const async_switch_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  async_switch_test_none_multi.foo1 = function(a) {
    return dart.async(function*(a) {
      let k = 0;
      switch (a) {
        case 1:
        {
          yield 3;
          k = dart.notNull(k) + 1;
          break;
        }
        case 2:
        {
          k = dart.notNull(k) + dart.notNull(core.int._check(a));
          return dart.notNull(k) + 2;
        }
      }
      return k;
    }, dart.dynamic, a);
  };
  dart.fn(async_switch_test_none_multi.foo1, dynamicTodynamic());
  async_switch_test_none_multi.foo2 = function(a) {
    return dart.async(function*(a) {
      let k = 0;
      switch (yield a) {
        case 1:
        {
          yield 3;
          k = dart.notNull(k) + 1;
          break;
        }
        case 2:
        {
          k = dart.notNull(k) + dart.notNull(core.int._check(yield a));
          return dart.notNull(k) + 2;
        }
      }
      return k;
    }, dart.dynamic, a);
  };
  dart.fn(async_switch_test_none_multi.foo2, dynamicTodynamic());
  async_switch_test_none_multi.foo3 = function(a) {
    return dart.async(function*(a) {
      let k = 0;
      switch (a) {
        case 1:
        {
          k = dart.notNull(k) + 1;
          break;
        }
        case 2:
        {
          k = dart.notNull(k) + dart.notNull(core.int._check(a));
          return dart.notNull(k) + 2;
        }
      }
      return k;
    }, dart.dynamic, a);
  };
  dart.fn(async_switch_test_none_multi.foo3, dynamicTodynamic());
  async_switch_test_none_multi.foo4 = function(value) {
    return dart.async(function*(value) {
      let k = 0;
      switch (yield value) {
        case 1:
        {
          k = k + 1;
          break;
        }
        case 2:
        {
          k = k + 2;
          return 2 + k;
        }
      }
      return k;
    }, dart.dynamic, value);
  };
  dart.fn(async_switch_test_none_multi.foo4, dynamicTodynamic());
  async_switch_test_none_multi.futureOf = function(a) {
    return dart.async(function*(a) {
      return yield a;
    }, dart.dynamic, a);
  };
  dart.fn(async_switch_test_none_multi.futureOf, dynamicTodynamic());
  async_switch_test_none_multi.test = function() {
    return dart.async(function*() {
      expect$.Expect.equals(1, yield async_switch_test_none_multi.foo1(1));
      expect$.Expect.equals(4, yield async_switch_test_none_multi.foo1(2));
      expect$.Expect.equals(0, yield async_switch_test_none_multi.foo1(3));
      expect$.Expect.equals(1, yield async_switch_test_none_multi.foo2(async_switch_test_none_multi.futureOf(1)));
      expect$.Expect.equals(4, yield async_switch_test_none_multi.foo2(async_switch_test_none_multi.futureOf(2)));
      expect$.Expect.equals(0, yield async_switch_test_none_multi.foo2(async_switch_test_none_multi.futureOf(3)));
      expect$.Expect.equals(1, yield async_switch_test_none_multi.foo3(1));
      expect$.Expect.equals(4, yield async_switch_test_none_multi.foo3(2));
      expect$.Expect.equals(0, yield async_switch_test_none_multi.foo3(3));
      expect$.Expect.equals(1, yield async_switch_test_none_multi.foo4(async_switch_test_none_multi.futureOf(1)));
      expect$.Expect.equals(4, yield async_switch_test_none_multi.foo4(async_switch_test_none_multi.futureOf(2)));
      expect$.Expect.equals(0, yield async_switch_test_none_multi.foo4(async_switch_test_none_multi.futureOf(3)));
    }, dart.dynamic);
  };
  dart.fn(async_switch_test_none_multi.test, VoidTodynamic());
  async_switch_test_none_multi.main = function() {
    async_helper$.asyncStart();
    dart.dsend(async_switch_test_none_multi.test(), 'then', dart.fn(_ => async_helper$.asyncEnd(), dynamicTovoid()));
  };
  dart.fn(async_switch_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.async_switch_test_none_multi = async_switch_test_none_multi;
});
