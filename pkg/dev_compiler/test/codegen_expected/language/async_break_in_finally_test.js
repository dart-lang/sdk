dart_library.library('language/async_break_in_finally_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__async_break_in_finally_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const async_break_in_finally_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  async_break_in_finally_test.then43 = function() {
    return dart.async(function*() {
      label:
        try {
          return yield 42;
        } finally {
          break label;
        }
      return yield 43;
    }, dart.dynamic);
  };
  dart.fn(async_break_in_finally_test.then43, VoidTodynamic());
  async_break_in_finally_test.then42 = function() {
    return dart.async(function*() {
      label:
        try {
          return yield 42;
        } finally {
        }
      return yield 43;
    }, dart.dynamic);
  };
  dart.fn(async_break_in_finally_test.then42, VoidTodynamic());
  async_break_in_finally_test.now43 = function() {
    label:
      try {
        return 42;
      } finally {
        break label;
      }
    return 43;
  };
  dart.fn(async_break_in_finally_test.now43, VoidTodynamic());
  async_break_in_finally_test.now42 = function() {
    label:
      try {
        return 42;
      } finally {
      }
    return 43;
  };
  dart.fn(async_break_in_finally_test.now42, VoidTodynamic());
  async_break_in_finally_test.test = function() {
    return dart.async(function*() {
      expect$.Expect.equals(42, yield async_break_in_finally_test.then42());
      expect$.Expect.equals(43, yield async_break_in_finally_test.then43());
      expect$.Expect.equals(42, async_break_in_finally_test.now42());
      expect$.Expect.equals(43, async_break_in_finally_test.now43());
    }, dart.dynamic);
  };
  dart.fn(async_break_in_finally_test.test, VoidTodynamic());
  async_break_in_finally_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(async_break_in_finally_test.test(), 'then', dart.fn(_ => async_helper$.asyncEnd(), dynamicTovoid()));
  };
  dart.fn(async_break_in_finally_test.main, VoidTodynamic());
  // Exports:
  exports.async_break_in_finally_test = async_break_in_finally_test;
});
