dart_library.library('language/async_and_or_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__async_and_or_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const async_and_or_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let FutureOfvoid = () => (FutureOfvoid = dart.constFn(async.Future$(dart.void)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let FnTodynamic = () => (FnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [VoidTovoid()])))();
  let VoidToFutureOfvoid = () => (VoidToFutureOfvoid = dart.constFn(dart.definiteFunctionType(FutureOfvoid(), [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  async_and_or_test.confuse = function(x) {
    return x;
  };
  dart.fn(async_and_or_test.confuse, dynamicTodynamic());
  async_and_or_test.test1 = function() {
    return dart.async(function*() {
      expect$.Expect.isFalse(dart.test(yield async_and_or_test.confuse(false)) && dart.test(yield async_and_or_test.confuse(false)));
      expect$.Expect.isFalse(dart.test(yield async_and_or_test.confuse(false)) && dart.test(yield async_and_or_test.confuse(true)));
      expect$.Expect.isFalse(dart.test(yield async_and_or_test.confuse(true)) && dart.test(yield async_and_or_test.confuse(false)));
      expect$.Expect.isTrue(dart.test(yield async_and_or_test.confuse(true)) && dart.test(yield async_and_or_test.confuse(true)));
      expect$.Expect.isFalse(dart.test(yield async_and_or_test.confuse(false)) || dart.test(yield async_and_or_test.confuse(false)));
      expect$.Expect.isTrue(dart.test(yield async_and_or_test.confuse(false)) || dart.test(yield async_and_or_test.confuse(true)));
      expect$.Expect.isTrue(dart.test(yield async_and_or_test.confuse(true)) || dart.test(yield async_and_or_test.confuse(false)));
      expect$.Expect.isTrue(dart.test(yield async_and_or_test.confuse(true)) || dart.test(yield async_and_or_test.confuse(true)));
    }, dart.dynamic);
  };
  dart.fn(async_and_or_test.test1, VoidTodynamic());
  async_and_or_test.trace = null;
  async_and_or_test.traceA = function(x) {
    async_and_or_test.trace = dart.notNull(async_and_or_test.trace) + "a";
    return x;
  };
  dart.fn(async_and_or_test.traceA, dynamicTodynamic());
  async_and_or_test.traceB = function(x) {
    async_and_or_test.trace = dart.notNull(async_and_or_test.trace) + "b";
    return x;
  };
  dart.fn(async_and_or_test.traceB, dynamicTodynamic());
  async_and_or_test.testEvaluation = function(fn) {
    return dart.async(function*(fn) {
      async_and_or_test.trace = "";
      yield fn();
    }, dart.dynamic, fn);
  };
  dart.fn(async_and_or_test.testEvaluation, FnTodynamic());
  async_and_or_test.test2 = function() {
    return dart.async(function*() {
      yield async_and_or_test.testEvaluation(dart.fn(() => dart.async(function*() {
        expect$.Expect.isFalse(dart.test(yield async_and_or_test.confuse(async_and_or_test.traceA(false))) && dart.test(yield async_and_or_test.confuse(async_and_or_test.traceB(false))));
        expect$.Expect.equals("a", async_and_or_test.trace);
      }, dart.void), VoidToFutureOfvoid()));
      yield async_and_or_test.testEvaluation(dart.fn(() => dart.async(function*() {
        expect$.Expect.isFalse(dart.test(yield async_and_or_test.confuse(async_and_or_test.traceA(false))) && dart.test(yield async_and_or_test.confuse(async_and_or_test.traceB(true))));
        expect$.Expect.equals("a", async_and_or_test.trace);
      }, dart.void), VoidToFutureOfvoid()));
      yield async_and_or_test.testEvaluation(dart.fn(() => dart.async(function*() {
        expect$.Expect.isFalse(dart.test(yield async_and_or_test.confuse(async_and_or_test.traceA(true))) && dart.test(yield async_and_or_test.confuse(async_and_or_test.traceB(false))));
        expect$.Expect.equals("ab", async_and_or_test.trace);
      }, dart.void), VoidToFutureOfvoid()));
      yield async_and_or_test.testEvaluation(dart.fn(() => dart.async(function*() {
        expect$.Expect.isTrue(dart.test(yield async_and_or_test.confuse(async_and_or_test.traceA(true))) && dart.test(yield async_and_or_test.confuse(async_and_or_test.traceB(true))));
        expect$.Expect.equals("ab", async_and_or_test.trace);
      }, dart.void), VoidToFutureOfvoid()));
      yield async_and_or_test.testEvaluation(dart.fn(() => dart.async(function*() {
        expect$.Expect.isFalse(dart.test(yield async_and_or_test.confuse(async_and_or_test.traceA(false))) || dart.test(yield async_and_or_test.confuse(async_and_or_test.traceB(false))));
        expect$.Expect.equals("ab", async_and_or_test.trace);
      }, dart.void), VoidToFutureOfvoid()));
      yield async_and_or_test.testEvaluation(dart.fn(() => dart.async(function*() {
        expect$.Expect.isTrue(dart.test(yield async_and_or_test.confuse(async_and_or_test.traceA(false))) || dart.test(yield async_and_or_test.confuse(async_and_or_test.traceB(true))));
        expect$.Expect.equals("ab", async_and_or_test.trace);
      }, dart.void), VoidToFutureOfvoid()));
      yield async_and_or_test.testEvaluation(dart.fn(() => dart.async(function*() {
        expect$.Expect.isTrue(dart.test(yield async_and_or_test.confuse(async_and_or_test.traceA(true))) || dart.test(yield async_and_or_test.confuse(async_and_or_test.traceB(false))));
        expect$.Expect.equals("a", async_and_or_test.trace);
      }, dart.void), VoidToFutureOfvoid()));
      yield async_and_or_test.testEvaluation(dart.fn(() => dart.async(function*() {
        expect$.Expect.isTrue(dart.test(yield async_and_or_test.confuse(async_and_or_test.traceA(true))) || dart.test(yield async_and_or_test.confuse(async_and_or_test.traceB(true))));
        expect$.Expect.equals("a", async_and_or_test.trace);
      }, dart.void), VoidToFutureOfvoid()));
    }, dart.dynamic);
  };
  dart.fn(async_and_or_test.test2, VoidTodynamic());
  async_and_or_test.test = function() {
    return dart.async(function*() {
      yield async_and_or_test.test1();
      yield async_and_or_test.test2();
    }, dart.dynamic);
  };
  dart.fn(async_and_or_test.test, VoidTodynamic());
  async_and_or_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(async_and_or_test.test(), 'then', dart.fn(_ => async_helper$.asyncEnd(), dynamicTovoid()));
  };
  dart.fn(async_and_or_test.main, VoidTodynamic());
  // Exports:
  exports.async_and_or_test = async_and_or_test;
});
