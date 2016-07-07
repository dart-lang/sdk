dart_library.library('language/async_star_cancel_and_throw_in_finally_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__async_star_cancel_and_throw_in_finally_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const async_star_cancel_and_throw_in_finally_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicToFuture = () => (dynamicToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  async_star_cancel_and_throw_in_finally_test.foo = function() {
    return dart.asyncStar(function*(stream) {
      try {
        let i = 0;
        while (true) {
          if (stream.add(i++)) return;
          yield;
        }
      } finally {
        dart.throw("Error");
      }
    }, dart.dynamic);
  };
  dart.fn(async_star_cancel_and_throw_in_finally_test.foo, VoidTodynamic());
  async_star_cancel_and_throw_in_finally_test.test = function() {
    return dart.async(function*() {
      let completer = async.Completer.new();
      let s = null;
      s = dart.dsend(async_star_cancel_and_throw_in_finally_test.foo(), 'listen', dart.fn(e => dart.async(function*(e) {
        expect$.Expect.equals(0, e);
        try {
          yield dart.dsend(s, 'cancel');
          expect$.Expect.fail("Did not throw");
        } catch (e) {
          expect$.Expect.equals("Error", e);
          completer.complete();
        }

      }, dart.dynamic, e), dynamicToFuture()));
      yield completer.future;
    }, dart.dynamic);
  };
  dart.fn(async_star_cancel_and_throw_in_finally_test.test, VoidTodynamic());
  async_star_cancel_and_throw_in_finally_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(async_star_cancel_and_throw_in_finally_test.test(), 'then', dart.fn(_ => async_helper$.asyncEnd(), dynamicTovoid()));
  };
  dart.fn(async_star_cancel_and_throw_in_finally_test.main, VoidTodynamic());
  // Exports:
  exports.async_star_cancel_and_throw_in_finally_test = async_star_cancel_and_throw_in_finally_test;
});
