dart_library.library('language/code_after_try_is_executed_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__code_after_try_is_executed_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const code_after_try_is_executed_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  code_after_try_is_executed_test_none_multi.main = function() {
    let exception = null;
    try {
      dart.throw('foo');
    } catch (ex) {
      if (core.String.is(ex)) {
        exception = ex;
      } else
        throw ex;
    }

    expect$.Expect.isTrue(typeof exception == 'string');
  };
  dart.fn(code_after_try_is_executed_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.code_after_try_is_executed_test_none_multi = code_after_try_is_executed_test_none_multi;
});
