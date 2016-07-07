dart_library.library('language/async_return_types_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__async_return_types_test_none_multi(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const async_return_types_test_none_multi = Object.create(null);
  let FutureOfint = () => (FutureOfint = dart.constFn(async.Future$(core.int)))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  let VoidToFutureOfint = () => (VoidToFutureOfint = dart.constFn(dart.definiteFunctionType(FutureOfint(), [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  async_return_types_test_none_multi.foo1 = function() {
    return dart.async(function*() {
      return 3;
    }, dart.dynamic);
  };
  dart.fn(async_return_types_test_none_multi.foo1, VoidToFuture());
  async_return_types_test_none_multi.foo2 = function() {
    return dart.async(function*() {
      return 3;
    }, core.int);
  };
  dart.fn(async_return_types_test_none_multi.foo2, VoidToFutureOfint());
  async_return_types_test_none_multi.foo3 = function() {
    return dart.async(function*() {
      return "String";
    }, dart.dynamic);
  };
  dart.fn(async_return_types_test_none_multi.foo3, VoidTodynamic());
  async_return_types_test_none_multi.foo4 = function() {
    return dart.async(function*() {
      return "String";
    }, dart.dynamic);
  };
  dart.fn(async_return_types_test_none_multi.foo4, VoidTodynamic());
  async_return_types_test_none_multi.foo5 = function() {
    return dart.async(function*() {
      return 3;
    }, dart.dynamic);
  };
  dart.fn(async_return_types_test_none_multi.foo5, VoidTodynamic());
  async_return_types_test_none_multi.foo6 = function() {
    return dart.async(function*() {
      return FutureOfint().value(3);
    }, core.int);
  };
  dart.fn(async_return_types_test_none_multi.foo6, VoidToFutureOfint());
  async_return_types_test_none_multi.foo7 = function() {
    return dart.async(function*() {
      return FutureOfint().value(3);
    }, dart.dynamic);
  };
  dart.fn(async_return_types_test_none_multi.foo7, VoidTodynamic());
  async_return_types_test_none_multi.test = function() {
    return dart.async(function*() {
      expect$.Expect.equals(3, yield async_return_types_test_none_multi.foo1());
      expect$.Expect.equals(3, yield async_return_types_test_none_multi.foo2());
      expect$.Expect.equals("String", yield async_return_types_test_none_multi.foo3());
      expect$.Expect.equals("String", yield async_return_types_test_none_multi.foo4());
      expect$.Expect.equals(3, yield async_return_types_test_none_multi.foo5());
      expect$.Expect.equals(3, yield yield async_return_types_test_none_multi.foo6());
      expect$.Expect.equals(3, yield yield async_return_types_test_none_multi.foo7());
    }, dart.dynamic);
  };
  dart.fn(async_return_types_test_none_multi.test, VoidTodynamic());
  async_return_types_test_none_multi.main = function() {
    async_helper$.asyncTest(async_return_types_test_none_multi.test);
  };
  dart.fn(async_return_types_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.async_return_types_test_none_multi = async_return_types_test_none_multi;
});
