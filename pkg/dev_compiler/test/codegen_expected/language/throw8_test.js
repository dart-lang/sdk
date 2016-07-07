dart_library.library('language/throw8_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__throw8_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const throw8_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  throw8_test.finallyExecutionCount = 0;
  throw8_test.bar = function() {
    try {
      try {
        return 499;
      } catch (e) {
        let st = dart.stackTrace(e);
        throw e;
      }

    } finally {
      throw8_test.finallyExecutionCount = dart.notNull(throw8_test.finallyExecutionCount) + 1;
      dart.throw("quit finally with throw");
    }
  };
  dart.fn(throw8_test.bar, VoidTodynamic());
  throw8_test.main = function() {
    let hasThrown = false;
    try {
      throw8_test.bar();
    } catch (x) {
      hasThrown = true;
      expect$.Expect.equals(1, throw8_test.finallyExecutionCount);
    }

    expect$.Expect.isTrue(hasThrown);
  };
  dart.fn(throw8_test.main, VoidTodynamic());
  // Exports:
  exports.throw8_test = throw8_test;
});
