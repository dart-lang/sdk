dart_library.library('language/async_finally_rethrow_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__async_finally_rethrow_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_finally_rethrow_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  async_finally_rethrow_test.foo = function() {
    return dart.async(function*() {
      try {
        yield 1;
        dart.throw("error");
      } catch (e) {
        if (core.String.is(e)) {
          yield 2;
          dart.throw(e);
        } else
          throw e;
      }
 finally {
        yield 3;
      }
    }, dart.dynamic);
  };
  dart.fn(async_finally_rethrow_test.foo, VoidTodynamic());
  async_finally_rethrow_test.main = function() {
    return dart.async(function*() {
      let error = "no error";
      try {
        yield async_finally_rethrow_test.foo();
      } catch (e) {
        error = core.String._check(e);
      }

      expect$.Expect.equals("error", error);
    }, dart.dynamic);
  };
  dart.fn(async_finally_rethrow_test.main, VoidTodynamic());
  // Exports:
  exports.async_finally_rethrow_test = async_finally_rethrow_test;
});
