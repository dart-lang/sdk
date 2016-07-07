dart_library.library('language/async_rethrow_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__async_rethrow_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_rethrow_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  async_rethrow_test.exceptionString = "exceptionalString";
  async_rethrow_test.throwString = function() {
    return dart.async(function*() {
      try {
        dart.throw(async_rethrow_test.exceptionString);
      } catch (e) {
        yield 1;
        dart.throw(e);
      }

    }, dart.dynamic);
  };
  dart.fn(async_rethrow_test.throwString, VoidTodynamic());
  async_rethrow_test.rethrowString = function() {
    return dart.async(function*() {
      try {
        dart.throw(async_rethrow_test.exceptionString);
      } catch (e) {
        yield 1;
        throw e;
      }

    }, dart.dynamic);
  };
  dart.fn(async_rethrow_test.rethrowString, VoidTodynamic());
  async_rethrow_test.testThrow = function() {
    let f = async.Future._check(async_rethrow_test.throwString());
    f.then(dart.dynamic)(dart.fn(v => {
      expect$.Expect.fail("Exception not thrown");
    }, dynamicTodynamic()), {onError: dart.fn(e => {
        expect$.Expect.equals(async_rethrow_test.exceptionString, e);
      }, dynamicTodynamic())});
  };
  dart.fn(async_rethrow_test.testThrow, VoidTodynamic());
  async_rethrow_test.testRethrow = function() {
    let f = async.Future._check(async_rethrow_test.rethrowString());
    f.then(dart.dynamic)(dart.fn(v => {
      expect$.Expect.fail("Exception not thrown");
    }, dynamicTodynamic()), {onError: dart.fn(e => {
        expect$.Expect.equals(async_rethrow_test.exceptionString, e);
      }, dynamicTodynamic())});
  };
  dart.fn(async_rethrow_test.testRethrow, VoidTodynamic());
  async_rethrow_test.main = function() {
    async_rethrow_test.testThrow();
    async_rethrow_test.testRethrow();
  };
  dart.fn(async_rethrow_test.main, VoidTodynamic());
  // Exports:
  exports.async_rethrow_test = async_rethrow_test;
});
