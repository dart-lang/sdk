dart_library.library('language/await_exceptions_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__await_exceptions_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const await_exceptions_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  await_exceptions_test.bar = function(p) {
    return dart.async(function*(p) {
      return p;
    }, dart.dynamic, p);
  };
  dart.fn(await_exceptions_test.bar, dynamicTodynamic());
  await_exceptions_test.baz = function(p) {
    return async.Future.new(dart.fn(() => p, VoidTodynamic()));
  };
  dart.fn(await_exceptions_test.baz, dynamicTodynamic());
  await_exceptions_test.test0_1 = function() {
    return dart.async(function*() {
      dart.throw(1);
    }, dart.dynamic);
  };
  dart.fn(await_exceptions_test.test0_1, VoidTodynamic());
  await_exceptions_test.test0 = function() {
    return dart.async(function*() {
      try {
        yield await_exceptions_test.test0_1();
      } catch (e) {
        expect$.Expect.equals(1, e);
      }

    }, dart.dynamic);
  };
  dart.fn(await_exceptions_test.test0, VoidTodynamic());
  await_exceptions_test.test1_1 = function() {
    return dart.async(function*() {
      dart.throw(1);
    }, dart.dynamic);
  };
  dart.fn(await_exceptions_test.test1_1, VoidTodynamic());
  await_exceptions_test.test1_2 = function() {
    return dart.async(function*() {
      try {
        yield await_exceptions_test.test1_1();
      } catch (e) {
        dart.throw(dart.dsend(e, '+', 1));
      }

    }, dart.dynamic);
  };
  dart.fn(await_exceptions_test.test1_2, VoidTodynamic());
  await_exceptions_test.test1 = function() {
    return dart.async(function*() {
      try {
        yield await_exceptions_test.test1_2();
      } catch (e) {
        expect$.Expect.equals(2, e);
      }

    }, dart.dynamic);
  };
  dart.fn(await_exceptions_test.test1, VoidTodynamic());
  await_exceptions_test.test2 = function() {
    return dart.async(function*() {
      let x = null;
      let test2_1 = dart.fn(() => dart.async(function*() {
        try {
          dart.throw('a');
        } catch (e) {
          dart.throw(dart.dsend(e, '+', 'b'));
        }

      }, dart.dynamic), VoidToFuture());
      try {
        try {
          yield test2_1();
        } catch (e) {
          let y = (yield await_exceptions_test.bar(dart.dsend(e, '+', 'c')));
          dart.throw(y);
        }

      } catch (e) {
        x = dart.dsend(e, '+', 'd');
        return '?';
      }
 finally {
        return x;
      }
      return '!';
    }, dart.dynamic);
  };
  dart.fn(await_exceptions_test.test2, VoidTodynamic());
  await_exceptions_test.test = function() {
    return dart.async(function*() {
      let result = null;
      for (let i = 0; i < 10; i++) {
        yield await_exceptions_test.test0();
        yield await_exceptions_test.test1();
        result = (yield await_exceptions_test.test2());
        expect$.Expect.equals('abcd', result);
      }
      yield 1;
    }, dart.dynamic);
  };
  dart.fn(await_exceptions_test.test, VoidTodynamic());
  await_exceptions_test.foo = function() {
    dart.throw("Error");
  };
  dart.fn(await_exceptions_test.foo, VoidTodynamic());
  await_exceptions_test.awaitFoo = function() {
    return dart.async(function*() {
      yield await_exceptions_test.foo();
    }, dart.dynamic);
  };
  dart.fn(await_exceptions_test.awaitFoo, VoidTodynamic());
  await_exceptions_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(dart.dsend(await_exceptions_test.test(), 'then', dart.fn(_ => dart.dsend(await_exceptions_test.awaitFoo(), 'then', dart.fn(_ => expect$.Expect.fail("Should have thrown"), dynamicTovoid()), {onError: dart.fn(error => expect$.Expect.equals("Error", error), dynamicTovoid())}), dynamicTodynamic())), 'whenComplete', async_helper$.asyncEnd);
  };
  dart.fn(await_exceptions_test.main, VoidTodynamic());
  // Exports:
  exports.await_exceptions_test = await_exceptions_test;
});
